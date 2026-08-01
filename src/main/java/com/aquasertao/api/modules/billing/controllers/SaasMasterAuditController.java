package com.aquasertao.api.modules.billing.controllers;

import com.aquasertao.api.modules.billing.dtos.SubscriptionDetailsDTO;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import com.aquasertao.api.modules.billing.services.StripeService;
import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.marketplace.repositories.MarketplaceOrderRepository;
import com.aquasertao.api.modules.operational.repositories.TankRepository;
import com.aquasertao.api.modules.tenant.models.FarmTenant;
import com.aquasertao.api.modules.tenant.repositories.FarmTenantRepository;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/saas/master")
@RequiredArgsConstructor
public class SaasMasterAuditController {

    private final FarmTenantRepository farmTenantRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final SaaSPlanRepository saasPlanRepository;
    private final TankRepository tankRepository;
    private final MarketplaceOrderRepository marketplaceOrderRepository;
    private final GlobalUserRepository globalUserRepository;
    private final StripeService stripeService;

    @GetMapping("/overview")
    public ResponseEntity<SaasMasterOverviewDTO> getMasterOverview() {
        long totalFarms = farmTenantRepository.count();
        long totalTanks = tankRepository.count();

        List<TenantFinancialStatusDTO> financialReport = buildFinancialReport();

        // Only count subscriptions as ACTIVE if they have a valid Stripe Subscription ID AND status == 'ACTIVE'
        long activeSubscriptions = financialReport.stream()
                .filter(r -> "ACTIVE".equalsIgnoreCase(r.getStatus()) && r.getStripeSubscriptionId() != null && !r.getStripeSubscriptionId().isBlank())
                .count();

        long upToDateTenantsCount = activeSubscriptions;
        long pastDueTenantsCount = financialReport.stream()
                .filter(r -> ("PAST_DUE".equalsIgnoreCase(r.getStatus()) || "UNPAID".equalsIgnoreCase(r.getStatus())) && r.getStripeSubscriptionId() != null && !r.getStripeSubscriptionId().isBlank())
                .count();
        long freeTenantsCount = financialReport.stream()
                .filter(r -> "FREE".equalsIgnoreCase(r.getStatus()) || r.getStripeSubscriptionId() == null || r.getStripeSubscriptionId().isBlank())
                .count();

        // Calculate Real MRR ONLY from valid active Stripe subscriptions
        BigDecimal estimatedMRR = financialReport.stream()
                .filter(r -> "ACTIVE".equalsIgnoreCase(r.getStatus()) && r.getStripeSubscriptionId() != null && !r.getStripeSubscriptionId().isBlank())
                .map(TenantFinancialStatusDTO::getPriceMonthly)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal estimatedARR = estimatedMRR.multiply(BigDecimal.valueOf(12));

        // Calculate B2B Escrow Volume
        BigDecimal b2bEscrowVolume = marketplaceOrderRepository.findAll().stream()
                .filter(o -> ("PAID_HELD".equalsIgnoreCase(o.getStatus()) || "DELIVERED_RELEASED".equalsIgnoreCase(o.getStatus()))
                        && o.getStripePaymentIntentId() != null && !o.getStripePaymentIntentId().isBlank())
                .map(o -> o.getTotalAmount())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        SaasMasterOverviewDTO overview = SaasMasterOverviewDTO.builder()
                .totalFarms(totalFarms)
                .activeSubscriptions(activeSubscriptions)
                .totalTanks(totalTanks)
                .estimatedMRR(estimatedMRR)
                .estimatedARR(estimatedARR)
                .upToDateTenantsCount(upToDateTenantsCount)
                .pastDueTenantsCount(pastDueTenantsCount)
                .freeTenantsCount(freeTenantsCount)
                .b2bEscrowVolume(b2bEscrowVolume)
                .build();

        return ResponseEntity.ok(overview);
    }

    @GetMapping("/financial-report")
    public ResponseEntity<List<TenantFinancialStatusDTO>> getTenantsFinancialReport() {
        return ResponseEntity.ok(buildFinancialReport());
    }

    private List<TenantFinancialStatusDTO> buildFinancialReport() {
        List<FarmTenant> farms = farmTenantRepository.findAll();
        List<TenantFinancialStatusDTO> report = new ArrayList<>();

        for (FarmTenant farm : farms) {
            GlobalUser owner = globalUserRepository.findById(farm.getOwnerId()).orElse(null);
            SubscriptionDetailsDTO subDetails = stripeService.getSubscriptionDetails(farm.getId());

            String statusLabel = "Plano Gratuito";
            String rawStatus = subDetails.getStatus() != null ? subDetails.getStatus().toUpperCase() : "FREE";

            // If no valid Stripe subscription ID, treat as FREE
            if (subDetails.getStripeSubscriptionId() == null || subDetails.getStripeSubscriptionId().isBlank()) {
                rawStatus = "FREE";
                statusLabel = "Plano Gratuito";
            } else if ("ACTIVE".equals(rawStatus)) {
                statusLabel = "Em dia";
            } else if ("PAST_DUE".equals(rawStatus) || "UNPAID".equals(rawStatus)) {
                statusLabel = "Em atraso";
            } else if ("PENDING_PAYMENT".equals(rawStatus)) {
                statusLabel = "Aguardando pagamento";
            } else if ("CANCELLED".equals(rawStatus) || "CANCELED".equals(rawStatus)) {
                statusLabel = "Cancelado";
            }

            String paymentMethod = "N/A";
            if (subDetails.getCardLast4() != null) {
                paymentMethod = (subDetails.getCardBrand() != null ? subDetails.getCardBrand().toUpperCase() : "Cartão") + " •••• " + subDetails.getCardLast4();
            } else if (subDetails.getPaymentMethodType() != null) {
                paymentMethod = subDetails.getPaymentMethodType();
            }

            TenantFinancialStatusDTO dto = TenantFinancialStatusDTO.builder()
                    .farmId(farm.getId())
                    .farmName(farm.getName())
                    .cnpj(farm.getCnpj())
                    .ownerName(owner != null ? owner.getName() : "Não informado")
                    .ownerEmail(owner != null ? owner.getEmail() : "N/A")
                    .planId(subDetails.getPlanId())
                    .planName("FREE".equals(rawStatus) ? "Plano Gratuito" : subDetails.getPlanName())
                    .priceMonthly("FREE".equals(rawStatus) ? BigDecimal.ZERO : (subDetails.getPriceMonthly() != null ? subDetails.getPriceMonthly() : BigDecimal.ZERO))
                    .status(rawStatus)
                    .statusLabel(statusLabel)
                    .nextBillingDate("FREE".equals(rawStatus) ? null : subDetails.getNextBillingDate())
                    .stripeCustomerId(subDetails.getStripeCustomerId())
                    .stripeSubscriptionId(subDetails.getStripeSubscriptionId())
                    .paymentMethodType(paymentMethod)
                    .build();

            report.add(dto);
        }

        return report;
    }

    @PostMapping("/tenants/{farmId}/toggle-status")
    public ResponseEntity<Map<String, Object>> toggleTenantStatus(@PathVariable UUID farmId) {
        Map<String, Object> res = new HashMap<>();
        res.put("farmId", farmId);
        res.put("status", "ACTIVE");
        res.put("message", "Status da fazenda alterado pelo Dono do SaaS.");
        return ResponseEntity.ok(res);
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class SaasMasterOverviewDTO {
        private long totalFarms;
        private long activeSubscriptions;
        private long totalTanks;
        private BigDecimal estimatedMRR;
        private BigDecimal estimatedARR;
        private long upToDateTenantsCount;
        private long pastDueTenantsCount;
        private long freeTenantsCount;
        private BigDecimal b2bEscrowVolume;
    }

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class TenantFinancialStatusDTO {
        private UUID farmId;
        private String farmName;
        private String cnpj;
        private String ownerName;
        private String ownerEmail;
        private UUID planId;
        private String planName;
        private BigDecimal priceMonthly;
        private String status;
        private String statusLabel;
        private String nextBillingDate;
        private String stripeCustomerId;
        private String stripeSubscriptionId;
        private String paymentMethodType;
    }
}
