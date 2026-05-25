package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.FeedingRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface FeedingRecordRepository extends JpaRepository<FeedingRecord, UUID> {
    
    // Strict Tenant Isolation + Pagination
    Page<FeedingRecord> findByFarmId(UUID farmId, Pageable pageable);
    
    // Optionally find by tank
    Page<FeedingRecord> findByTankId(UUID tankId, Pageable pageable);

    java.util.Optional<FeedingRecord> findByIdAndFarmId(UUID id, UUID farmId);

    boolean existsByIdAndFarmId(UUID id, UUID farmId);
}
