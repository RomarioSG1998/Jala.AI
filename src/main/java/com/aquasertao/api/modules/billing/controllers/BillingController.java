package com.aquasertao.api.modules.billing.controllers;

import com.aquasertao.api.modules.billing.dtos.CheckoutSessionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.CheckoutSessionResponseDTO;
import com.aquasertao.api.modules.billing.dtos.PlanDetailsDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionResponseDTO;
import com.aquasertao.api.modules.billing.services.BillingService;
import com.aquasertao.api.modules.billing.services.StripeService;
import com.stripe.exception.StripeException;
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
    private final StripeService stripeService;

    @PostMapping("/subscribe")
    public ResponseEntity<SubscriptionResponseDTO> subscribeFarm(@RequestBody SubscriptionRequestDTO requestDTO) {
        return ResponseEntity.ok(billingService.subscribeFarm(requestDTO));
    }

    @PostMapping("/create-checkout-session")
    public ResponseEntity<CheckoutSessionResponseDTO> createCheckoutSession(@RequestBody CheckoutSessionRequestDTO requestDTO) throws StripeException {
        return ResponseEntity.ok(stripeService.createCheckoutSession(requestDTO));
    }

    @PostMapping("/webhook")
    public ResponseEntity<String> handleWebhook(@RequestBody String payload, @RequestHeader(value = "Stripe-Signature", required = false) String sigHeader) {
        stripeService.processWebhook(payload, sigHeader);
        return ResponseEntity.ok("OK");
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

    @GetMapping("/farm/{farmId}/plan")
    public ResponseEntity<PlanDetailsDTO> getFarmActivePlan(@PathVariable UUID farmId) {
        return ResponseEntity.ok(billingService.getFarmActivePlan(farmId));
    }
}
