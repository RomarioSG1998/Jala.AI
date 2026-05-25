package com.aquasertao.api.modules.billing.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "saas_plan")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SaaSPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(nullable = false, unique = true, length = 50)
    private String name;

    @Column(name = "max_tanks", nullable = false)
    private Integer maxTanks;

    @Column(name = "max_users", nullable = false)
    private Integer maxUsers;

    @Column(name = "price_monthly", nullable = false, precision = 10, scale = 2)
    private BigDecimal priceMonthly;
}
