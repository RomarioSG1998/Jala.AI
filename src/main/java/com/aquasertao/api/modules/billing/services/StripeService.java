package com.aquasertao.api.modules.billing.services;

import com.aquasertao.api.modules.billing.dtos.CheckoutSessionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.CheckoutSessionResponseDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionDetailsDTO;
import com.aquasertao.api.modules.billing.models.Invoice;
import com.aquasertao.api.modules.billing.models.SaaSPlan;
import com.aquasertao.api.modules.billing.models.Subscription;
import com.aquasertao.api.modules.billing.repositories.InvoiceRepository;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import com.aquasertao.api.modules.marketplace.services.MarketplaceOrderService;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.exception.StripeException;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
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
    private final MarketplaceOrderService marketplaceOrderService;

    @Value("${stripe.secret-key:}")
    private String secretKey;

    @Value("${stripe.webhook-secret:}")
    private String webhookSecret;

    private RequestOptions getRequestOptions() {
        String key = (secretKey != null && !secretKey.trim().isEmpty()) ? secretKey.trim() : null;
        if (key == null || key.isEmpty()) {
            key = System.getProperty("STRIPE_SECRET_KEY");
        }
        if (key == null || key.trim().isEmpty()) {
            key = System.getenv("STRIPE_SECRET_KEY");
        }
        if (key == null || key.trim().isEmpty()) {
            key = com.stripe.Stripe.apiKey;
        }
        if (key != null && !key.trim().isEmpty()) {
            key = key.trim();
            com.stripe.Stripe.apiKey = key;
            return RequestOptions.builder().setApiKey(key).build();
        }
        return RequestOptions.builder().build();
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
            case "payment_intent.succeeded":
                handlePaymentIntentSucceeded(event);
                break;
            default:
                log.info("Evento do Stripe não tratado: {}", event.getType());
                break;
        }
    }

    private void handlePaymentIntentSucceeded(Event event) {
        PaymentIntent intent = (PaymentIntent) event.getDataObjectDeserializer().getObject().orElse(null);
        if (intent != null && intent.getId() != null) {
            log.info("Processando payment_intent.succeeded para ID: {}", intent.getId());
            marketplaceOrderService.handlePaymentSucceeded(intent.getId());
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

    @Transactional(readOnly = true)
    public SubscriptionDetailsDTO getSubscriptionDetails(UUID farmId) {
        RequestOptions options = getRequestOptions();

        SaaSPlan freePlan = saasPlanRepository.findByName("Free")
                .orElseGet(() -> saasPlanRepository.findAll().stream().findFirst().orElse(null));

        SubscriptionDetailsDTO freeDto = SubscriptionDetailsDTO.builder()
                .farmId(farmId)
                .planName(freePlan != null ? freePlan.getName() : "Gratuito")
                .maxTanks(freePlan != null ? freePlan.getMaxTanks() : 3)
                .maxUsers(freePlan != null ? freePlan.getMaxUsers() : 2)
                .priceMonthly(freePlan != null ? freePlan.getPriceMonthly() : BigDecimal.ZERO)
                .status("FREE")
                .paymentMethodType("N/A")
                .cancelAtPeriodEnd(false)
                .build();

        Subscription sub = subscriptionRepository.findByFarmIdAndStatus(farmId, "ACTIVE")
                .orElseGet(() -> subscriptionRepository.findFirstByFarmIdOrderByStartDateDesc(farmId).orElse(null));

        if (sub == null || sub.getStripeSubscriptionId() == null || sub.getStripeSubscriptionId().isBlank()) {
            return freeDto;
        }

        SaaSPlan plan = saasPlanRepository.findById(sub.getPlanId()).orElse(null);

        SubscriptionDetailsDTO.SubscriptionDetailsDTOBuilder builder = SubscriptionDetailsDTO.builder()
                .subscriptionId(sub.getId())
                .farmId(sub.getFarmId())
                .planId(sub.getPlanId())
                .planName(plan != null ? plan.getName() : "Plano Ativo")
                .maxTanks(plan != null ? plan.getMaxTanks() : 3)
                .maxUsers(plan != null ? plan.getMaxUsers() : 2)
                .priceMonthly(plan != null ? plan.getPriceMonthly() : BigDecimal.ZERO)
                .status(sub.getStatus())
                .startDate(sub.getStartDate() != null ? sub.getStartDate().toString() : null)
                .endDate(sub.getEndDate() != null ? sub.getEndDate().toString() : null)
                .nextBillingDate(sub.getEndDate() != null ? sub.getEndDate().toString() : null)
                .stripeCustomerId(sub.getStripeCustomerId())
                .stripeSubscriptionId(sub.getStripeSubscriptionId())
                .cancelAtPeriodEnd("CANCELLED".equalsIgnoreCase(sub.getStatus()));

        // Query Stripe API in real-time
        try {
            com.stripe.model.Subscription stripeSub = com.stripe.model.Subscription.retrieve(
                    sub.getStripeSubscriptionId(),
                    options
            );

                if (stripeSub != null) {
                    if (stripeSub.getCurrentPeriodEnd() != null) {
                        java.time.LocalDate periodEnd = java.time.Instant.ofEpochSecond(stripeSub.getCurrentPeriodEnd())
                                .atZone(java.time.ZoneId.systemDefault())
                                .toLocalDate();
                        builder.nextBillingDate(periodEnd.toString());
                        builder.endDate(periodEnd.toString());
                    }

                    builder.cancelAtPeriodEnd(Boolean.TRUE.equals(stripeSub.getCancelAtPeriodEnd()));

                    if (stripeSub.getStatus() != null) {
                        String stripeStatus = stripeSub.getStatus().toUpperCase();
                        if ("CANCELED".equals(stripeStatus)) {
                            builder.status("CANCELLED");
                        } else if ("ACTIVE".equals(stripeStatus)) {
                            builder.status("ACTIVE");
                        }
                    }

                    if (stripeSub.getDefaultPaymentMethod() != null) {
                        try {
                            com.stripe.model.PaymentMethod pm = com.stripe.model.PaymentMethod.retrieve(
                                    stripeSub.getDefaultPaymentMethod(),
                                    options
                            );
                            if (pm != null && pm.getCard() != null) {
                                builder.paymentMethodType("card");
                                builder.cardBrand(pm.getCard().getBrand());
                                builder.cardLast4(pm.getCard().getLast4());
                            }
                        } catch (Exception pmEx) {
                            log.warn("Could not retrieve Stripe PaymentMethod: {}", pmEx.getMessage());
                        }
                    }
                }
        } catch (Exception e) {
            log.warn("Failed to fetch real-time Stripe subscription info: {}", e.getMessage());
            return freeDto;
        }

        SubscriptionDetailsDTO result = builder.build();
        if (result.getPaymentMethodType() == null) {
            result.setPaymentMethodType("Stripe Checkout");
        }

        return result;
    }

    @Transactional
    public SubscriptionDetailsDTO cancelSubscription(UUID farmId) {
        RequestOptions options = getRequestOptions();

        Subscription sub = subscriptionRepository.findByFarmIdAndStatus(farmId, "ACTIVE")
                .orElseGet(() -> subscriptionRepository.findFirstByFarmIdOrderByStartDateDesc(farmId)
                        .orElseThrow(() -> new IllegalArgumentException("Nenhuma assinatura ativa encontrada para cancelamento.")));

        if (sub.getStripeSubscriptionId() != null && !sub.getStripeSubscriptionId().isBlank()) {
            try {
                com.stripe.model.Subscription stripeSub = com.stripe.model.Subscription.retrieve(
                        sub.getStripeSubscriptionId(),
                        options
                );
                if (stripeSub != null) {
                    stripeSub.cancel(com.stripe.param.SubscriptionCancelParams.builder().build(), options);
                    log.info("Assinatura do Stripe cancelada: {}", sub.getStripeSubscriptionId());
                }
            } catch (Exception e) {
                log.error("Erro ao cancelar assinatura no Stripe: {}", e.getMessage());
            }
        }

        sub.setStatus("CANCELLED");
        subscriptionRepository.save(sub);

        return getSubscriptionDetails(farmId);
    }

    /**
     * Sincroniza a criação/edição de um plano de SaaS com o Stripe em tempo real.
     * Gera um Product e um Price mensal em BRL na API do Stripe.
     */
    public SaaSPlan syncPlanWithStripe(SaaSPlan plan) {
        try {
            RequestOptions options = getRequestOptions();
            if (options.getApiKey() == null || options.getApiKey().isBlank()) {
                log.warn("Chave do Stripe não configurada. Atribuindo IDs simulados para o plano {}.", plan.getName());
                plan.setStripeProductId("prod_simulated_" + UUID.randomUUID().toString().substring(0, 8));
                plan.setStripePriceId("price_simulated_" + UUID.randomUUID().toString().substring(0, 8));
                return plan;
            }

            // 1. Criar ou reutilizar Produto no Stripe
            String productId = plan.getStripeProductId();
            if (productId == null || productId.isBlank() || productId.startsWith("prod_simulated_")) {
                com.stripe.param.ProductCreateParams productParams = com.stripe.param.ProductCreateParams.builder()
                        .setName("AquaGestor " + plan.getName())
                        .setDescription((plan.getDescription() != null && !plan.getDescription().isBlank())
                                ? plan.getDescription()
                                : "Plano " + plan.getName() + " do AquaGestor SaaS - Limite de " + plan.getMaxTanks() + " tanques.")
                        .build();

                com.stripe.model.Product stripeProduct = com.stripe.model.Product.create(productParams, options);
                productId = stripeProduct.getId();
                plan.setStripeProductId(productId);
            }

            // 2. Criar Tabela de Preço no Stripe
            long amountCents = plan.getPriceMonthly().multiply(BigDecimal.valueOf(100)).longValue();
            com.stripe.param.PriceCreateParams priceParams = com.stripe.param.PriceCreateParams.builder()
                    .setProduct(productId)
                    .setUnitAmount(amountCents)
                    .setCurrency("brl")
                    .setRecurring(
                            com.stripe.param.PriceCreateParams.Recurring.builder()
                                    .setInterval(com.stripe.param.PriceCreateParams.Recurring.Interval.MONTH)
                                    .build()
                    )
                    .build();

            com.stripe.model.Price stripePrice = com.stripe.model.Price.create(priceParams, options);
            plan.setStripePriceId(stripePrice.getId());
            log.info("Plano {} sincronizado no Stripe com Sucesso! Product: {}, Price: {}", plan.getName(), productId, stripePrice.getId());

        } catch (Exception e) {
            log.error("Erro ao sincronizar plano com o Stripe API: {}", e.getMessage(), e);
            if (plan.getStripeProductId() == null) {
                plan.setStripeProductId("prod_fallback_" + UUID.randomUUID().toString().substring(0, 8));
            }
            if (plan.getStripePriceId() == null) {
                plan.setStripePriceId("price_fallback_" + UUID.randomUUID().toString().substring(0, 8));
            }
        }
        return plan;
    }
}
