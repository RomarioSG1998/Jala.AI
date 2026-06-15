package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.BiometricsRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BiometricsRecordRepository extends JpaRepository<BiometricsRecord, UUID> {
    List<BiometricsRecord> findByTankIdAndFarmIdOrderByRecordDateDesc(UUID tankId, UUID farmId);
    List<BiometricsRecord> findByFarmId(UUID farmId);
    java.util.Optional<BiometricsRecord> findByIdAndFarmId(UUID id, UUID farmId);
}
