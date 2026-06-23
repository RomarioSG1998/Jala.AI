package com.aquasertao.supplier.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.util.UUID;

@Entity
@Table(name = "national_supplier", schema = "supplier_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NationalSupplier {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "company_name", nullable = false, length = 255)
    private String companyName;

    @Column(unique = true, length = 20)
    private String cnpj;

    @Column(name = "supply_type", nullable = false, length = 100)
    private String supplyType;

    @Column(name = "is_approved", nullable = false)
    private Boolean isApproved;

    @PrePersist
    public void prePersist() {
        if (isApproved == null) {
            isApproved = false;
        }
    }
}
