package com.aquasertao.api.modules.general.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "approval_request", schema = "general_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApprovalRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(name = "requester_id", nullable = false)
    private UUID requesterId;

    @Column(name = "requested_action", nullable = false, columnDefinition = "TEXT")
    private String requestedAction;

    @Column(nullable = false, length = 50)
    private String status; // PENDING, APPROVED, REJECTED

    @Column(name = "request_date", nullable = false, updatable = false)
    private LocalDateTime requestDate;

    @PrePersist
    public void prePersist() {
        if (requestDate == null) {
            requestDate = LocalDateTime.now();
        }
    }
}
