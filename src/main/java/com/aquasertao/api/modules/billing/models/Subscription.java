package com.aquasertao.api.modules.billing.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "subscription")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Subscription {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "plan_id", nullable = false)
    private UUID planId;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(nullable = false, length = 20)
    private String status; // ACTIVE, EXPIRED, CANCELLED
}
