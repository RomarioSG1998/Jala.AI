package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.WaterQuality;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface WaterQualityRepository extends JpaRepository<WaterQuality, UUID> {
    
    // Strict Tenant Isolation + Pagination
    Page<WaterQuality> findByFarmId(UUID farmId, Pageable pageable);
}
