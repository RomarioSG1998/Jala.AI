package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "inventory")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Inventory {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    // Strict Tenant Isolation
    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "item_name", nullable = false, length = 150)
    private String itemName;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal quantity;

    @Column(length = 50)
    private String unit;

    @Column(length = 100)
    private String type; // e.g., FEED, MEDICINE, EQUIPMENT
}
