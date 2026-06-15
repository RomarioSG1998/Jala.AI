package com.aquasertao.api.modules.operational.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class InventoryRequestDTO {
    
    // Required to isolate data per Farm
    private UUID farmId;
    
    private String itemName;
    private BigDecimal quantity;
    private String unit;
    private String type;
    private String power;
    private BigDecimal unitCost;
}
