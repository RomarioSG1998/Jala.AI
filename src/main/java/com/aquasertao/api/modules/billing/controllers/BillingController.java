package com.aquasertao.api.modules.billing.controllers;

import com.aquasertao.api.modules.billing.dtos.SubscriptionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionResponseDTO;
import com.aquasertao.api.modules.billing.services.BillingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/billing")
@RequiredArgsConstructor
public class BillingController {

    private final BillingService billingService;

    @PostMapping("/subscribe")
    public ResponseEntity<SubscriptionResponseDTO> subscribeFarm(@RequestBody SubscriptionRequestDTO requestDTO) {
        return ResponseEntity.ok(billingService.subscribeFarm(requestDTO));
    }
}
