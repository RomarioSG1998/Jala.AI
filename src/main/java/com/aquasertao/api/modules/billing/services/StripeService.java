package com.aquasertao.api.modules.billing.services;

import com.aquasertao.api.modules.billing.dtos.CheckoutSessionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.CheckoutSessionResponseDTO;
import com.aquasertao.api.modules.billing.models.Invoice;
import com.aquasertao.api.modules.billing.models.SaaSPlan;
import com.aquasertao.api.modules.billing.models.Subscription;
import com.aquasertao.api.modules.billing.repositories.InvoiceRepository;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.checkout.Session;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import com.stripe.net.RequestOptions;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class StripeService {

    private final SaaSPlanRepository saasPlanRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final InvoiceRepository invoiceRepository;

    @Value("${stripe.secret-key:}")
    private String secretKey;

    @Value("${stripe.webhook-secret:}")
    private String webhookSecret;

    private RequestOptions getRequestOptions() {
        String key = (secretKey != null && !secretKey.trim().isEmpty())
                ? secretKey.trim()
                : com.stripe.Stripe.apiKey;
        if (key != null && !key.trim().isEmpty()) {
            com.stripe.Stripe.apiKey = key.trim();
        }
        return RequestOptions.builder().setApiKey(key).build();
    }

    @Transactional
    public CheckoutSessionResponseDTO createCheckoutSession(CheckoutSessionRequestDTO request) throws StripeException {
        RequestOptions options = getRequestOptions();

        SaaSPlan plan = saasPlanRepository.findById(request.getPlanId())
                .orElseThrow(() -> new IllegalArgumentException("Plano não encontrado."));

        long unitAmountCents = plan.getPriceMonthly()
                .multiply(BigDecimal.valueOf(100))
                .longValue();

        String successUrl = (request.getSuccessUrl() != null && !request.getSuccessUrl().isBlank())
                ? request.getSuccessUrl()
                : "http://localhost:8082/#/payment-success?session_id={CHECKOUT_SESSION_ID}";

        String cancelUrl = (request.getCancelUrl() != null && !request.getCancelUrl().isBlank())
                ? request.getCancelUrl()
                : "http://localhost:8082/#/payment-cancel";

        SessionCreateParams params = SessionCreateParams.builder()
                .setMode(SessionCreateParams.Mode.SUBSCRIPTION)
                .setSuccessUrl(successUrl)
                .setCancelUrl(cancelUrl)
                .addLineItem(
                        SessionCreateParams.LineItem.builder()
                                .setQuantity(1L)
                                .setPriceData(
                                        SessionCreateParams.LineItem.PriceData.builder()
                                                .setCurrency("brl")
                                                .setUnitAmount(unitAmountCents)
                                                .setProductData(
                                                        SessionCreateParams.LineItem.PriceData.ProductData.builder()
                                                                .setName("AquaGestor - " + plan.getName())
                                                                .setDescription("Assinatura mensal do plano " + plan.getName() + " (até " + plan.getMaxTanks() + " tanques)")
                                                                .build()
                                                )
                                                .setRecurring(
                                                        SessionCreateParams.LineItem.PriceData.Recurring.builder()
                                                                .setInterval(SessionCreateParams.LineItem.PriceData.Recurring.Interval.MONTH)
                                                                .build()
                                                )
                                                .build()
                                )
                                .build()
                )
                .putMetadata("farmId", request.getFarmId().toString())
                .putMetadata("planId", request.getPlanId().toString())
                .build();

        Session session = Session.create(params, options);

        // Upsert subscription record in PENDING_PAYMENT status
        Subscription sub = subscriptionRepository.findByFarmIdAndStatus(request.getFarmId(), "ACTIVE")
                .orElseGet(() -> subscriptionRepository.findByFarmIdAndStatus(request.getFarmId(), "PENDING_PAYMENT")
                        .orElse(Subscription.builder()
                                .farmId(request.getFarmId())
                                .startDate(LocalDate.now())
                                .endDate(LocalDate.now().plusMonths(1))
                                .build()));

        sub.setPlanId(request.getPlanId());
        sub.setStatus("PENDING_PAYMENT");
        sub.setStripeCheckoutSessionId(session.getId());
        subscriptionRepository.save(sub);

        log.info("Sessão do Stripe Checkout criada: {} para farmId: {}", session.getId(), request.getFarmId());

        return CheckoutSessionResponseDTO.builder()
                .checkoutUrl(session.getUrl())
                .sessionId(session.getId())
                .build();
    }

    @Transactional
    public void processWebhook(String payload, String sigHeader) {
        Event event;
        if (webhookSecret != null && !webhookSecret.trim().isEmpty() && sigHeader != null) {
            try {
                event = Webhook.constructEvent(payload, sigHeader, webhookSecret.trim());
            } catch (SignatureVerificationException e) {
                log.error("Assinatura de Webhook do Stripe inválida", e);
                throw new IllegalArgumentException("Webhook signature verification failed.");
            }
        } else {
            event = Event.GSON.fromJson(payload, Event.class);
        }

        log.info("Recebido evento Stripe Webhook: {}", event.getType());

        switch (event.getType()) {
            case "checkout.session.completed":
                handleCheckoutSessionCompleted(event);
                break;
            case "customer.subscription.deleted":
                handleSubscriptionDeleted(event);
                break;
            default:
                log.info("Evento do Stripe não tratado: {}", event.getType());
                break;
        }
    }

    private void handleCheckoutSessionCompleted(Event event) {
        Session session = (Session) event.getDataObjectDeserializer().getObject().orElse(null);
        if (session == null) {
            log.warn("Objeto Session nulo no evento checkout.session.completed");
            return;
        }

        String sessionId = session.getId();
        String customerId = session.getCustomer();
        String subscriptionId = session.getSubscription();

        log.info("Processando checkout.session.completed para sessionId: {}", sessionId);

        Subscription subscription = subscriptionRepository.findByStripeCheckoutSessionId(sessionId)
                .orElseGet(() -> {
                    String farmIdStr = session.getMetadata() != null ? session.getMetadata().get("farmId") : null;
                    if (farmIdStr != null) {
                        return subscriptionRepository.findByFarmIdAndStatus(UUID.fromString(farmIdStr), "PENDING_PAYMENT")
                                .orElse(null);
                    }
                    return null;
                });

        if (subscription != null) {
            subscription.setStatus("ACTIVE");
            subscription.setStripeCustomerId(customerId);
            subscription.setStripeSubscriptionId(subscriptionId);
            subscription.setStartDate(LocalDate.now());
            subscription.setEndDate(LocalDate.now().plusMonths(1));
            subscriptionRepository.save(subscription);

            // Gerar fatura paga
            SaaSPlan plan = saasPlanRepository.findById(subscription.getPlanId()).orElse(null);
            Invoice invoice = Invoice.builder()
                    .subscriptionId(subscription.getId())
                    .amount(plan != null ? plan.getPriceMonthly() : BigDecimal.ZERO)
                    .dueDate(LocalDate.now())
                    .status("PAID")
                    .build();
            invoiceRepository.save(invoice);

            log.info("Assinatura ativada com sucesso para farmId: {}", subscription.getFarmId());
        } else {
            log.warn("Nenhuma assinatura pendente encontrada para a sessão do Stripe: {}", sessionId);
        }
    }

    private void handleSubscriptionDeleted(Event event) {
        com.stripe.model.Subscription stripeSub = (com.stripe.model.Subscription) event.getDataObjectDeserializer().getObject().orElse(null);
        if (stripeSub != null) {
            subscriptionRepository.findByStripeSubscriptionId(stripeSub.getId())
                    .ifPresent(sub -> {
                        sub.setStatus("CANCELLED");
                        subscriptionRepository.save(sub);
                        log.info("Assinatura cancelada via Stripe para farmId: {}", sub.getFarmId());
                    });
        }
    }
}
