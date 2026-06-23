package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "mortality_record", schema = "ops_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MortalityRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "tank_id", nullable = false)
    private UUID tankId;

    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    @Column(name = "cause")
    private String cause;

    @Column(name = "record_date", nullable = false)
    private LocalDateTime recordDate;

    @PrePersist
    public void prePersist() {
        if (recordDate == null) {
            recordDate = LocalDateTime.now();
        }
    }
}
