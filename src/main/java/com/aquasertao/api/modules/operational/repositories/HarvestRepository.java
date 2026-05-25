package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.Harvest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface HarvestRepository extends JpaRepository<Harvest, UUID> {
    
    // Strict Tenant Isolation + Pagination
    Page<Harvest> findByFarmId(UUID farmId, Pageable pageable);
}
