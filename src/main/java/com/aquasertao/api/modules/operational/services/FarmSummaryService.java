package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.FarmSummaryDTO;
import com.aquasertao.api.modules.operational.models.Tank;
import com.aquasertao.api.modules.operational.models.FeedingRecord;
import com.aquasertao.api.modules.operational.repositories.TankRepository;
import com.aquasertao.api.modules.operational.repositories.FeedingRecordRepository;
import com.aquasertao.api.modules.operational.repositories.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FarmSummaryService {

    private final TankRepository tankRepository;
    private final FeedingRecordRepository feedingRecordRepository;
    private final MaintenanceRepository maintenanceRepository;

    public FarmSummaryDTO getFarmSummary(UUID farmId) {
        // 1. Tanks aggregations
        List<Tank> tanks = tankRepository.findByFarmId(farmId);
        long totalTanks = tanks.size();
        long activeTanks = tanks.stream()
                .filter(t -> "ACTIVE".equalsIgnoreCase(t.getStatus()))
                .count();
        long totalFishCapacity = tanks.stream()
                .filter(t -> t.getFishCapacity() != null)
                .mapToLong(Tank::getFishCapacity)
                .sum();

        // 2. Feeding today
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.atTime(LocalTime.MAX);
        List<FeedingRecord> feedingsToday = feedingRecordRepository.findByFarmIdAndFeedingTimeBetween(
                farmId, startOfDay, endOfDay
        );
        BigDecimal feedingTodayKg = feedingsToday.stream()
                .map(FeedingRecord::getQuantity)
                .filter(q -> q != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 3. Pending maintenance
        long pendingMaintenanceTasks = maintenanceRepository.countByFarmIdAndStatus(farmId, "PENDING");

        return FarmSummaryDTO.builder()
                .totalTanks(totalTanks)
                .activeTanks(activeTanks)
                .totalFishCapacity(totalFishCapacity)
                .feedingTodayKg(feedingTodayKg)
                .pendingMaintenanceTasks(pendingMaintenanceTasks)
                .build();
    }
}
