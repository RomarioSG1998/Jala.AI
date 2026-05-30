package com.aquasertao.api.modules.billing.controllers;

import com.aquasertao.api.modules.billing.dtos.PlanDetailsDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionResponseDTO;
import com.aquasertao.api.modules.billing.services.BillingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/billing")
@RequiredArgsConstructor
public class BillingController {

    private final BillingService billingService;

    @PostMapping("/subscribe")
    public ResponseEntity<SubscriptionResponseDTO> subscribeFarm(@RequestBody SubscriptionRequestDTO requestDTO) {
        return ResponseEntity.ok(billingService.subscribeFarm(requestDTO));
    }

    @GetMapping("/plans/details")
    public ResponseEntity<List<PlanDetailsDTO>> getAllPlansWithDetails() {
        return ResponseEntity.ok(billingService.getAllPlansWithDetails());
    }

    @GetMapping("/plans/{planId}/subscriptions")
    public ResponseEntity<List<SubscriptionResponseDTO>> getSubscriptionsByPlan(@PathVariable UUID planId) {
        return ResponseEntity.ok(billingService.getSubscriptionsByPlan(planId));
    }

    @GetMapping("/stats/active-subscriptions")
    public ResponseEntity<Long> getTotalActiveSubscriptions() {
        return ResponseEntity.ok(billingService.getTotalActiveSubscriptions());
    }
}
