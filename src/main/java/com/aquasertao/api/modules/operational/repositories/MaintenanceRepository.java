package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.Maintenance;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface MaintenanceRepository extends JpaRepository<Maintenance, UUID> {
    
    // Strict Tenant Isolation + Pagination
    Page<Maintenance> findByFarmId(UUID farmId, Pageable pageable);

    java.util.Optional<Maintenance> findByIdAndFarmId(UUID id, UUID farmId);

    boolean existsByIdAndFarmId(UUID id, UUID farmId);
}
