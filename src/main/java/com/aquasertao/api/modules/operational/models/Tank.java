package com.aquasertao.api.modules.operational.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "tank", schema = "ops_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Tank {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "farm_id", nullable = false)
    private UUID farmId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "fish_species", length = 100)
    private String fishSpecies;

    @Column(name = "fish_capacity")
    private Integer fishCapacity;

    /** Peso médio atual dos peixes em gramas */
    @Column(name = "average_weight_g")
    private Integer averageWeightG;

    /** Contagem acumulada de mortalidade no mês atual */
    @Column(name = "mortality_count")
    private Integer mortalityCount;

    /** Data prevista para a próxima despesca */
    @Column(name = "next_harvest_date")
    private LocalDate nextHarvestDate;

    /** Status operacional: ACTIVE ou INACTIVE */
    @Column(name = "status", length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    @Column(name = "custom_image", columnDefinition = "TEXT")
    private String customImage;
}
