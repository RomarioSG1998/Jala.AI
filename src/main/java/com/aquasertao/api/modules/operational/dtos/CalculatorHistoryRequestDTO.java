package com.aquasertao.api.modules.operational.dtos;

import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

@Data
public class CalculatorHistoryRequestDTO {
    private UUID farmId;
    private UUID tankId;         // optional
    private String species;
    private Integer quantity;
    private BigDecimal weightG;
    private BigDecimal biomassKg;
    private BigDecimal dailyFeedKg;
    private BigDecimal feedPerTreatmentKg;
    private Integer treatmentsPerDay;
    private String proteinLevel;
    private String granulometry;
    private Integer daysToHarvest;
    private BigDecimal temperatureC;
    private Boolean tempAlert;
}
