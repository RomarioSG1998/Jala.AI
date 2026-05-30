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
@Table(name = "feeding_record")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeedingRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    // Strict Tenant Isolation
    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "tank_id", nullable = false)
    private UUID tankId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "feed_id", nullable = false)
    private UUID feedId;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal quantity;

    @Column(name = "feeding_time", nullable = false, updatable = false)
    private LocalDateTime feedingTime;

    @PrePersist
    public void prePersist() {
        if (feedingTime == null) {
            feedingTime = LocalDateTime.now();
        }
    }
}
