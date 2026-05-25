package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.util.UUID;

@Entity
@Table(name = "tank")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Tank {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    // To maintain strict modular decoupling, we reference the farm_tenant by its UUID directly
    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "fish_species", length = 100)
    private String fishSpecies;

    @Column(name = "fish_capacity")
    private Integer fishCapacity;
}
