package com.aquasertao.api.modules.marketplace.models;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "marketplace_order", schema = "marketplace_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarketplaceOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "announcement_id", nullable = false)
    private UUID announcementId;

    @Column(name = "buyer_farm_id", nullable = false)
    private UUID buyerFarmId;

    @Column(name = "seller_farm_id", nullable = false)
    private UUID sellerFarmId;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    /** Status: PENDING_PAYMENT | PAID_HELD | DELIVERED_RELEASED | CANCELLED */
    @Column(nullable = false, length = 50)
    private String status;

    /** Payment Method: PIX | CARD */
    @Column(name = "payment_method", nullable = false, length = 50)
    private String paymentMethod;

    @Column(name = "stripe_payment_intent_id")
    private String stripePaymentIntentId;

    @Column(name = "stripe_client_secret")
    private String stripeClientSecret;

    @Column(name = "pix_qr_code", columnDefinition = "TEXT")
    private String pixQrCode;

    @Column(name = "pix_copy_paste", columnDefinition = "TEXT")
    private String pixCopyPaste;

    @Column(name = "buyer_name", length = 150)
    private String buyerName;

    @Column(name = "buyer_phone", length = 20)
    private String buyerPhone;

    @Column(name = "delivery_address", columnDefinition = "TEXT")
    private String deliveryAddress;

    @Column(name = "delivery_city", length = 100)
    private String deliveryCity;

    @Column(name = "delivery_state", length = 2)
    private String deliveryState;

    @Column(name = "delivery_notes", columnDefinition = "TEXT")
    private String deliveryNotes;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
