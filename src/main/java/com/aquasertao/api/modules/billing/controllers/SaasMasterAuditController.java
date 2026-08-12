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

import com.aquasertao.api.modules.general.services.NotificationService;

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
    private final NotificationService notificationService;

    @GetMapping("/overview")
    public ResponseEntity<SaasMasterOverviewDTO> getMasterOverview() {
        List<TenantFinancialStatusDTO> financialReport = buildFinancialReport();
        long totalFarms = Math.max(farmTenantRepository.count(), (long) financialReport.size());
        long totalTanks = tankRepository.count();

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
        try {
            return ResponseEntity.ok(buildFinancialReport());
        } catch (Exception e) {
            return ResponseEntity.ok(new ArrayList<>());
        }
    }

    private List<TenantFinancialStatusDTO> buildFinancialReport() {
        List<FarmTenant> farms = farmTenantRepository.findAll();
        List<TenantFinancialStatusDTO> report = new ArrayList<>();
        java.util.Set<UUID> processedUserIds = new java.util.HashSet<>();

        for (FarmTenant farm : farms) {
            GlobalUser owner = farm.getOwnerId() != null
                    ? globalUserRepository.findById(farm.getOwnerId()).orElse(null)
                    : null;
            if (owner != null) {
                processedUserIds.add(owner.getId());
            }

            SubscriptionDetailsDTO subDetails;
            try {
                subDetails = stripeService.getSubscriptionDetails(farm.getId());
            } catch (Exception e) {
                subDetails = null;
            }

            if (subDetails == null) {
                subDetails = SubscriptionDetailsDTO.builder()
                        .farmId(farm.getId())
                        .status("FREE")
                        .planName("Plano Gratuito")
                        .priceMonthly(BigDecimal.ZERO)
                        .paymentMethodType("N/A")
                        .build();
            }

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
                    .ownerId(owner != null ? owner.getId() : farm.getOwnerId())
                    .ownerName(owner != null ? owner.getName() : "Não informado")
                    .ownerEmail(owner != null ? owner.getEmail() : "N/A")
                    .userActive(owner != null ? Boolean.TRUE.equals(owner.getActive()) : true)
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

        // Include any registered users who do not own a farm tenant yet (e.g., Google sign-ups)
        List<GlobalUser> allUsers = globalUserRepository.findAll();
        for (GlobalUser user : allUsers) {
            if ("SAAS_ADMIN".equalsIgnoreCase(user.getAccountType())) {
                continue;
            }
            if (!processedUserIds.contains(user.getId())) {
                String cleanName = (user.getName() != null && !user.getName().isBlank()) ? user.getName() : "Usuário Cadastrado";
                TenantFinancialStatusDTO dto = TenantFinancialStatusDTO.builder()
                        .farmId(null)
                        .farmName("Fazenda de " + cleanName)
                        .cnpj("Cadastro Direto")
                        .ownerId(user.getId())
                        .ownerName(user.getName())
                        .ownerEmail(user.getEmail())
                        .userActive(Boolean.TRUE.equals(user.getActive()))
                        .planId(null)
                        .planName("Plano Gratuito")
                        .priceMonthly(BigDecimal.ZERO)
                        .status("FREE")
                        .statusLabel("Plano Gratuito")
                        .nextBillingDate(null)
                        .stripeCustomerId(null)
                        .stripeSubscriptionId(null)
                        .paymentMethodType("N/A")
                        .build();

                report.add(dto);
            }
        }

        return report;
    }

    @PostMapping("/users/{userId}/toggle-active")
    public ResponseEntity<Map<String, Object>> toggleUserActiveStatus(@PathVariable UUID userId) {
        GlobalUser user = globalUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado."));

        if ("SAAS_ADMIN".equalsIgnoreCase(user.getAccountType())) {
            throw new IllegalArgumentException("Não é permitido desativar a conta do Administrador Master.");
        }

        boolean newActiveStatus = !Boolean.TRUE.equals(user.getActive());
        user.setActive(newActiveStatus);
        globalUserRepository.save(user);

        try {
            notificationService.createNotification(
                    user.getId(),
                    newActiveStatus ? "Sua Conta Foi Ativada" : "Sua Conta Foi Desativada",
                    "USER_STATUS",
                    newActiveStatus
                            ? "Sua conta do AquaGestor foi reativada pelo Administrador. Você já pode acessar todos os módulos."
                            : "Sua conta foi temporariamente desativada pelo Administrador Master."
            );
        } catch (Exception ignored) {}

        Map<String, Object> res = new HashMap<>();
        res.put("userId", userId);
        res.put("active", newActiveStatus);
        res.put("message", newActiveStatus ? "Usuário ativado com sucesso." : "Usuário desativado com sucesso.");
        return ResponseEntity.ok(res);
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
        private UUID ownerId;
        private String ownerName;
        private String ownerEmail;
        private Boolean userActive;
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
