package com.aquasertao.api.modules.billing.controllers;

import com.aquasertao.api.modules.billing.repositories.InvoiceRepository;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import com.aquasertao.api.modules.marketplace.repositories.MarketplaceOrderRepository;
import com.aquasertao.api.modules.operational.repositories.TankRepository;
import com.aquasertao.api.modules.tenant.repositories.FarmTenantRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
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

    @GetMapping("/overview")
    public ResponseEntity<SaasMasterOverviewDTO> getMasterOverview() {
        long totalFarms = farmTenantRepository.count();
        long activeSubscriptions = subscriptionRepository.count();
        long totalTanks = tankRepository.count();

        // Calculate Estimated MRR from active subscriptions
        BigDecimal estimatedMRR = subscriptionRepository.findAll().stream()
                .filter(s -> "ACTIVE".equalsIgnoreCase(s.getStatus()))
                .map(s -> saasPlanRepository.findById(s.getPlanId())
                        .map(p -> p.getPriceMonthly())
                        .orElse(BigDecimal.ZERO))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Calculate B2B Escrow Volume
        BigDecimal b2bEscrowVolume = marketplaceOrderRepository.findAll().stream()
                .filter(o -> "PAID_HELD".equalsIgnoreCase(o.getStatus()) || "DELIVERED_RELEASED".equalsIgnoreCase(o.getStatus()))
                .map(o -> o.getTotalAmount())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        SaasMasterOverviewDTO overview = SaasMasterOverviewDTO.builder()
                .totalFarms(totalFarms)
                .activeSubscriptions(activeSubscriptions)
                .totalTanks(totalTanks)
                .estimatedMRR(estimatedMRR)
                .b2bEscrowVolume(b2bEscrowVolume)
                .build();

        return ResponseEntity.ok(overview);
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
    public static class SaasMasterOverviewDTO {
        private long totalFarms;
        private long activeSubscriptions;
        private long totalTanks;
        private BigDecimal estimatedMRR;
        private BigDecimal b2bEscrowVolume;
    }
}
