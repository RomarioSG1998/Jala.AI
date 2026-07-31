package com.aquasertao.api.modules.marketplace.models;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "supplier_profile", schema = "marketplace_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "farm_id", nullable = false, unique = true)
    private UUID farmId;

    @Column(name = "company_name", nullable = false, length = 200)
    private String companyName;

    @Column(name = "document_number", length = 20)
    private String documentNumber;

    @Column(name = "state_registration", length = 50)
    private String stateRegistration;

    @Column(length = 20)
    private String phone;

    @Column(length = 150)
    private String email;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(length = 100)
    private String city;

    @Column(length = 2)
    private String state;

    @Column(name = "pix_key", length = 100)
    private String pixKey;

    @Column(name = "pix_key_type", length = 20)
    private String pixKeyType;

    @Builder.Default
    @Column(nullable = false)
    private Boolean verified = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
