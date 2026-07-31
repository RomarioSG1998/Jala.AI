package com.aquasertao.api.modules.marketplace.controllers;

import com.aquasertao.api.modules.marketplace.dtos.CreateOrderRequestDTO;
import com.aquasertao.api.modules.marketplace.dtos.MarketplaceOrderDTO;
import com.aquasertao.api.modules.marketplace.services.MarketplaceOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/marketplace/orders")
@RequiredArgsConstructor
public class MarketplaceOrderController {

    private final MarketplaceOrderService orderService;

    @PostMapping("/create-checkout")
    public ResponseEntity<MarketplaceOrderDTO> createOrderCheckout(@RequestBody CreateOrderRequestDTO request) {
        return ResponseEntity.ok(orderService.createOrderCheckout(request));
    }

    @PostMapping("/{orderId}/confirm-delivery")
    public ResponseEntity<MarketplaceOrderDTO> confirmDelivery(
            @PathVariable UUID orderId,
            @RequestParam UUID farmId
    ) {
        return ResponseEntity.ok(orderService.confirmDelivery(orderId, farmId));
    }

    @GetMapping("/buyer/{farmId}")
    public ResponseEntity<List<MarketplaceOrderDTO>> getBuyerOrders(@PathVariable UUID farmId) {
        return ResponseEntity.ok(orderService.getBuyerOrders(farmId));
    }

    @GetMapping("/seller/{farmId}")
    public ResponseEntity<List<MarketplaceOrderDTO>> getSellerOrders(@PathVariable UUID farmId) {
        return ResponseEntity.ok(orderService.getSellerOrders(farmId));
    }
}
