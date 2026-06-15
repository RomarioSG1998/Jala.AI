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
public class WaterQualityRequestDTO {
    
    // Required to isolate data per Farm
    private UUID farmId;
    
    private UUID tankId;
    private BigDecimal ph;
    private BigDecimal temperature;
    private BigDecimal dissolvedOxygen;
    private BigDecimal ammonia;
    private BigDecimal nitrite;
    private BigDecimal alkalinity;
    private BigDecimal hardness;
    private BigDecimal solids;
}
