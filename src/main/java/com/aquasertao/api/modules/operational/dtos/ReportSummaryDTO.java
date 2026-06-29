package com.aquasertao.api.modules.operational.dtos;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class ReportSummaryDTO {

    // ── Crescimento ──────────────────────────────────────────────────────────
    private List<GrowthPoint> growthHistory;

    // ── Mortalidade ──────────────────────────────────────────────────────────
    private Integer totalMortality;
    private Double mortalityRate;
    private List<MortalityPoint> mortalityHistory;

    // ── Ração ────────────────────────────────────────────────────────────────
    private BigDecimal totalFeedKg;
    private BigDecimal totalFeedCost;
    private List<FeedingPoint> feedingHistory;

    // ── Despesca ─────────────────────────────────────────────────────────────
    private List<HarvestForecast> harvestForecasts;

    // ── Inner DTOs ───────────────────────────────────────────────────────────
    @Data @Builder
    public static class GrowthPoint {
        private String date;
        private Double avgWeightG;
        private String tankName;
    }

    @Data @Builder
    public static class MortalityPoint {
        private String date;
        private Integer count;
        private String cause;
    }

    @Data @Builder
    public static class FeedingPoint {
        private String date;
        private BigDecimal quantityKg;
        private BigDecimal cost;
    }

    @Data @Builder
    public static class HarvestForecast {
        private String tankName;
        private String expectedDate;
        private Integer estimatedFishCount;
        private Double estimatedWeightKg;
    }
}
