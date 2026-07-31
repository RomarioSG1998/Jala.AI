package com.aquasertao.api.modules.marketplace.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class MarketplaceOrderDTO {
    private UUID id;
    private UUID announcementId;
    private String announcementTitle;
    private String category;
    private UUID buyerFarmId;
    private UUID sellerFarmId;
    private String sellerName;
    private String buyerName;
    private String buyerPhone;
    private String deliveryAddress;
    private String deliveryCity;
    private String deliveryState;
    private String deliveryNotes;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalAmount;
    private String status; // PENDING_PAYMENT | PAID_HELD | DELIVERED_RELEASED | CANCELLED
    private String paymentMethod; // PIX | CARD
    private String stripePaymentIntentId;
    private String stripeClientSecret;
    private String pixQrCode;
    private String pixCopyPaste;
    private LocalDateTime createdAt;
    private LocalDateTime deliveredAt;
}
