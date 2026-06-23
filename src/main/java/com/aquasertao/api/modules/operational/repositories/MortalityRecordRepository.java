package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.MortalityRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MortalityRecordRepository extends JpaRepository<MortalityRecord, UUID> {
    Page<MortalityRecord> findByFarmId(UUID farmId, Pageable pageable);
    List<MortalityRecord> findByTankIdAndFarmIdOrderByRecordDateDesc(UUID tankId, UUID farmId);
    Optional<MortalityRecord> findByIdAndFarmId(UUID id, UUID farmId);
}
