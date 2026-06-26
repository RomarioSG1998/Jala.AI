package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "calculator_history", schema = "ops_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CalculatorHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    /** Optional: link to specific tank */
    @Column(name = "tank_id")
    private UUID tankId;

    @Column(name = "species", length = 50)
    private String species;

    @Column(name = "quantity")
    private Integer quantity;

    @Column(name = "weight_g", precision = 10, scale = 2)
    private BigDecimal weightG;

    @Column(name = "biomass_kg", precision = 10, scale = 2)
    private BigDecimal biomassKg;

    @Column(name = "daily_feed_kg", precision = 10, scale = 2)
    private BigDecimal dailyFeedKg;

    @Column(name = "feed_per_treatment_kg", precision = 10, scale = 2)
    private BigDecimal feedPerTreatmentKg;

    @Column(name = "treatments_per_day")
    private Integer treatmentsPerDay;

    @Column(name = "protein_level", length = 10)
    private String proteinLevel;

    @Column(name = "granulometry", length = 30)
    private String granulometry;

    @Column(name = "days_to_harvest")
    private Integer daysToHarvest;

    @Column(name = "temperature_c", precision = 5, scale = 1)
    private BigDecimal temperatureC;

    @Column(name = "temp_alert")
    private Boolean tempAlert;

    @Column(name = "calculated_at", nullable = false)
    private LocalDateTime calculatedAt;

    @PrePersist
    public void prePersist() {
        if (calculatedAt == null) calculatedAt = LocalDateTime.now();
    }
}
