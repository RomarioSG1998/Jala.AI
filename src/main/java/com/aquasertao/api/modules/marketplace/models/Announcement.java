package com.aquasertao.api.modules.marketplace.models;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "announcement", schema = "marketplace_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Announcement {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** Farm (tenant) owner of the announcement */
    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    /** Category: ALEVINOS | RACAO | EQUIPAMENTOS */
    @Column(nullable = false, length = 30)
    private String category;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    /** Seller display name */
    @Column(name = "seller_name", length = 150)
    private String sellerName;

    @Column(name = "seller_phone", length = 20)
    private String sellerPhone;

    /** "Cidade - UF" format */
    @Column(name = "seller_location", length = 100)
    private String sellerLocation;

    /** Optional image URL (uploaded externally or base64 stored) */
    @Column(name = "image_url", columnDefinition = "TEXT")
    private String imageUrl;

    @Column(name = "active")
    @Builder.Default
    private Boolean active = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
