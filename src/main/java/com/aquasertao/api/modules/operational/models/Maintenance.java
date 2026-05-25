package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "maintenance")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Maintenance {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    // Strict Tenant Isolation
    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "tank_id", nullable = false)
    private UUID tankId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, length = 50)
    private String status;

    @Column(name = "scheduled_date")
    private LocalDate scheduledDate;
}
