package com.aquasertao.api.modules.operational.services.calculator;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CalculationResult {
    private BigDecimal biomassKg;
    private BigDecimal dailyFeedKg; // Can be null or 0 for "Á vontade"
    private BigDecimal feedPerTreatmentKg;
    private Integer treatmentsPerDay;
    private String proteinLevel;
    private String granulometry;
    private Integer daysToHarvest;
    private Boolean tempAlert;
    private List<GrowthStep> growthSimulation;
}
