package com.aquasertao.api.modules.operational.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class TankRequestDTO {
    
    private UUID farmId;
    private String name;
    private String fishSpecies;
    private Integer fishCapacity;
    private Integer averageWeightG;
    private Integer mortalityCount;
    private String nextHarvestDate; // "yyyy-MM-dd" or null
    private String stockingDate;    // "yyyy-MM-dd" or null
    private Integer initialStockingQty;
    private Integer initialAverageWeightG;
    private String supplier;
    private String status;          // "ACTIVE" or "INACTIVE"
    private String customImage;
}
