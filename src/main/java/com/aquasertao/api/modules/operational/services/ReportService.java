package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import com.aquasertao.api.modules.operational.dtos.ReportSummaryDTO;
import com.aquasertao.api.modules.operational.models.BiometricsRecord;
import com.aquasertao.api.modules.operational.models.MortalityRecord;
import com.aquasertao.api.modules.operational.models.Tank;
import com.aquasertao.api.modules.operational.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final TankRepository tankRepository;
    private final BiometricsRecordRepository biometricsRecordRepository;
    private final MortalityRecordRepository mortalityRecordRepository;
    private final FeedingRecordRepository feedingRecordRepository;
    private final HarvestRepository harvestRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final SaaSPlanRepository saasPlanRepository;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public ReportSummaryDTO generateReport(UUID farmId) {

        List<Tank> tanks = tankRepository.findByFarmId(farmId);

        // ── 1. Growth history (all biometrics across all tanks) ──────────────
        List<ReportSummaryDTO.GrowthPoint> growthPoints = tanks.stream()
                .flatMap(tank -> {
                    List<BiometricsRecord> records =
                            biometricsRecordRepository.findByTankIdAndFarmIdOrderByRecordDateDesc(tank.getId(), farmId);
                    return records.stream().map(r -> ReportSummaryDTO.GrowthPoint.builder()
                            .date(r.getRecordDate().format(DATE_FMT))
                            .avgWeightG(r.getWeightG() != null ? r.getWeightG().doubleValue() : 0.0)
                            .tankName(tank.getName())
                            .build());
                })
                .sorted(Comparator.comparing(ReportSummaryDTO.GrowthPoint::getDate))
                .collect(Collectors.toList());

        // ── 2. Mortality ─────────────────────────────────────────────────────
        List<MortalityRecord> allMortality = tanks.stream()
                .flatMap(t -> mortalityRecordRepository
                        .findByTankIdAndFarmIdOrderByRecordDateDesc(t.getId(), farmId).stream())
                .collect(Collectors.toList());

        int totalMortality = allMortality.stream()
                .mapToInt(m -> m.getQuantity() != null ? m.getQuantity() : 0)
                .sum();

        long totalStocked = tanks.stream()
                .mapToLong(t -> t.getInitialStockingQty() != null ? t.getInitialStockingQty() : 0)
                .sum();

        double mortalityRate = totalStocked > 0
                ? Math.round((double) totalMortality / totalStocked * 10000.0) / 100.0
                : 0.0;

        List<ReportSummaryDTO.MortalityPoint> mortalityPoints = allMortality.stream()
                .map(m -> ReportSummaryDTO.MortalityPoint.builder()
                        .date(m.getRecordDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")))
                        .count(m.getQuantity())
                        .cause(m.getCause())
                        .build())
                .sorted(Comparator.comparing(ReportSummaryDTO.MortalityPoint::getDate))
                .collect(Collectors.toList());

        // ── 3. Feeding / Ração ────────────────────────────────────────────────
        // Group feeding records by date (last 30 days from all records)
        var allFeedings = feedingRecordRepository.findAll().stream()
                .filter(f -> f.getFarmId().equals(farmId))
                .collect(Collectors.toList());

        BigDecimal totalFeedKg = allFeedings.stream()
                .map(f -> f.getQuantity() != null ? f.getQuantity() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalFeedCost = allFeedings.stream()
                .map(f -> {
                    BigDecimal qty = f.getQuantity() != null ? f.getQuantity() : BigDecimal.ZERO;
                    BigDecimal cost = f.getUnitCost() != null ? f.getUnitCost() : BigDecimal.ZERO;
                    return qty.multiply(cost);
                })
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Group by date string
        Map<String, BigDecimal[]> feedByDate = new LinkedHashMap<>();
        allFeedings.forEach(f -> {
            String day = f.getFeedingTime().format(DATE_FMT);
            feedByDate.computeIfAbsent(day, k -> new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO});
            BigDecimal qty = f.getQuantity() != null ? f.getQuantity() : BigDecimal.ZERO;
            BigDecimal cost = f.getUnitCost() != null ? f.getUnitCost() : BigDecimal.ZERO;
            feedByDate.get(day)[0] = feedByDate.get(day)[0].add(qty);
            feedByDate.get(day)[1] = feedByDate.get(day)[1].add(qty.multiply(cost));
        });

        List<ReportSummaryDTO.FeedingPoint> feedingPoints = feedByDate.entrySet().stream()
                .map(e -> ReportSummaryDTO.FeedingPoint.builder()
                        .date(e.getKey())
                        .quantityKg(e.getValue()[0])
                        .cost(e.getValue()[1])
                        .build())
                .collect(Collectors.toList());

        // ── 4. Harvest Forecasts ─────────────────────────────────────────────
        List<ReportSummaryDTO.HarvestForecast> forecasts = tanks.stream()
                .filter(t -> t.getNextHarvestDate() != null)
                .map(t -> {
                    int fishCount = t.getInitialStockingQty() != null ? t.getInitialStockingQty() : 0;
                    int mortality = t.getMortalityCount() != null ? t.getMortalityCount() : 0;
                    int alive = Math.max(0, fishCount - mortality);
                    double avgWeightKg = t.getAverageWeightG() != null ? t.getAverageWeightG() / 1000.0 : 0.0;
                    return ReportSummaryDTO.HarvestForecast.builder()
                            .tankName(t.getName())
                            .expectedDate(t.getNextHarvestDate().format(DATE_FMT))
                            .estimatedFishCount(alive)
                            .estimatedWeightKg(Math.round(alive * avgWeightKg * 100.0) / 100.0)
                            .build();
                })
                .collect(Collectors.toList());

        return ReportSummaryDTO.builder()
                .growthHistory(growthPoints)
                .totalMortality(totalMortality)
                .mortalityRate(mortalityRate)
                .mortalityHistory(mortalityPoints)
                .totalFeedKg(totalFeedKg)
                .totalFeedCost(totalFeedCost)
                .feedingHistory(feedingPoints)
                .harvestForecasts(forecasts)
                .build();
    }

    // ── Plan guard: returns max tanks allowed for this farm ──────────────────
    public int getMaxTanksAllowed(UUID farmId) {
        return subscriptionRepository.findByFarmIdAndStatus(farmId, "ACTIVE")
                .map(sub -> saasPlanRepository.findById(sub.getPlanId())
                        .map(plan -> plan.getMaxTanks())
                        .orElse(1))
                .orElse(1); // default: FREE plan = 1 tank
    }
}
