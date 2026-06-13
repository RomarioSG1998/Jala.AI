package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "water_quality", schema = "ops_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WaterQuality {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    // Strict Tenant Isolation
    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "tank_id", nullable = false)
    private UUID tankId;

    @Column(precision = 4, scale = 2)
    private BigDecimal ph;

    @Column(precision = 5, scale = 2)
    private BigDecimal temperature;

    @Column(name = "dissolved_oxygen", precision = 5, scale = 2)
    private BigDecimal dissolvedOxygen;

    @Column(name = "measurement_time", nullable = false, updatable = false)
    private LocalDateTime measurementTime;

    @PrePersist
    public void prePersist() {
        if (measurementTime == null) {
            measurementTime = LocalDateTime.now();
        }
    }
}
