package com.aquasertao.api.modules.operational.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class FarmSummaryDTO {
    private long totalTanks;
    private long activeTanks;
    private long totalFishCapacity;
    private BigDecimal feedingTodayKg;
    private long pendingMaintenanceTasks;
}
