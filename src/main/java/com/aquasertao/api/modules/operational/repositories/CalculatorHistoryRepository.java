package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.CalculatorHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CalculatorHistoryRepository extends JpaRepository<CalculatorHistory, UUID> {
    List<CalculatorHistory> findByFarmIdOrderByCalculatedAtDesc(UUID farmId);
    List<CalculatorHistory> findByFarmIdAndTankIdOrderByCalculatedAtDesc(UUID farmId, UUID tankId);
}
