package com.aquasertao.api.modules.billing.services;

import com.aquasertao.api.modules.billing.dtos.PlanDetailsDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionResponseDTO;
import com.aquasertao.api.modules.billing.models.Invoice;
import com.aquasertao.api.modules.billing.models.SaaSPlan;
import com.aquasertao.api.modules.billing.models.Subscription;
import com.aquasertao.api.modules.billing.repositories.InvoiceRepository;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BillingService {

    private final SubscriptionRepository subscriptionRepository;
    private final SaaSPlanRepository saasPlanRepository;
    private final InvoiceRepository invoiceRepository;

    @Transactional
    public SubscriptionResponseDTO subscribeFarm(SubscriptionRequestDTO requestDTO) {

        // 1. Validate Plan
        SaaSPlan plan = saasPlanRepository.findById(requestDTO.getPlanId())
                .orElseThrow(() -> new IllegalArgumentException("SaaS Plan not found"));

        // 2. Check if active subscription already exists
        subscriptionRepository.findByFarmIdAndStatus(requestDTO.getFarmId(), "ACTIVE")
                .ifPresent(s -> {
                    throw new IllegalStateException("Farm already has an active subscription.");
                });

        // 3. Create Subscription
        Subscription subscription = Subscription.builder()
                .farmId(requestDTO.getFarmId())
                .planId(plan.getId())
                .startDate(LocalDate.now())
                .endDate(LocalDate.now().plusMonths(1))
                .status("ACTIVE")
                .build();

        Subscription savedSubscription = subscriptionRepository.save(subscription);

        // 4. Generate Initial Invoice
        Invoice invoice = Invoice.builder()
                .subscriptionId(savedSubscription.getId())
                .amount(plan.getPriceMonthly())
                .dueDate(LocalDate.now().plusDays(7))
                .status("PENDING")
                .build();

        invoiceRepository.save(invoice);

        return toResponseDTO(savedSubscription);
    }

    public List<SubscriptionResponseDTO> getSubscriptionsByPlan(UUID planId) {
        return subscriptionRepository.findByPlanId(planId)
                .stream()
                .map(this::toResponseDTO)
                .collect(Collectors.toList());
    }

    public List<PlanDetailsDTO> getAllPlansWithDetails() {
        return saasPlanRepository.findAll()
                .stream()
                .map(plan -> PlanDetailsDTO.builder()
                        .id(plan.getId())
                        .name(plan.getName())
                        .maxTanks(plan.getMaxTanks())
                        .maxUsers(plan.getMaxUsers())
                        .priceMonthly(plan.getPriceMonthly())
                        .stripeProductId(plan.getStripeProductId())
                        .stripePriceId(plan.getStripePriceId())
                        .description(plan.getDescription())
                        .active(plan.getActive())
                        .activeSubscribers(subscriptionRepository.countByPlanIdAndStatus(plan.getId(), "ACTIVE"))
                        .totalSubscribers(subscriptionRepository.findByPlanId(plan.getId()).size())
                        .build())
                .collect(Collectors.toList());
    }

    public long getTotalActiveSubscriptions() {
        return subscriptionRepository.countByStatus("ACTIVE");
    }

    public PlanDetailsDTO getFarmActivePlan(UUID farmId) {
        return subscriptionRepository.findByFarmIdAndStatus(farmId, "ACTIVE")
                .filter(sub -> sub.getStripeSubscriptionId() != null && !sub.getStripeSubscriptionId().isBlank())
                .flatMap(sub -> saasPlanRepository.findById(sub.getPlanId()))
                .map(plan -> PlanDetailsDTO.builder()
                        .id(plan.getId())
                        .name(plan.getName())
                        .maxTanks(plan.getMaxTanks())
                        .maxUsers(plan.getMaxUsers())
                        .priceMonthly(plan.getPriceMonthly())
                        .build())
                .orElseGet(() -> saasPlanRepository.findByName("Free")
                        .map(plan -> PlanDetailsDTO.builder()
                                .id(plan.getId())
                                .name(plan.getName())
                                .maxTanks(plan.getMaxTanks())
                                .maxUsers(plan.getMaxUsers())
                                .priceMonthly(plan.getPriceMonthly())
                                .build())
                        .orElse(PlanDetailsDTO.builder()
                                .name("Free")
                                .maxTanks(3)
                                .maxUsers(2)
                                .priceMonthly(java.math.BigDecimal.ZERO)
                                .build()));
    }

    private SubscriptionResponseDTO toResponseDTO(Subscription s) {
        return SubscriptionResponseDTO.builder()
                .id(s.getId())
                .farmId(s.getFarmId())
                .planId(s.getPlanId())
                .startDate(s.getStartDate())
                .endDate(s.getEndDate())
                .status(s.getStatus())
                .build();
    }
}
