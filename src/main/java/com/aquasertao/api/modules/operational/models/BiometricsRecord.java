package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "biometrics_record", schema = "ops_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BiometricsRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "tank_id", nullable = false)
    private UUID tankId;

    @Column(name = "weight_g", nullable = false)
    private Integer weightG;

    @Column(name = "record_date", nullable = false)
    private LocalDate recordDate;

    @PrePersist
    public void prePersist() {
        if (recordDate == null) {
            recordDate = LocalDate.now();
        }
    }
}
