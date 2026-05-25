package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.Tank;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface TankRepository extends JpaRepository<Tank, UUID> {
    
    // Strict Tenant Isolation + Pagination in a single query
    Page<Tank> findByFarmId(UUID farmId, Pageable pageable);

    java.util.Optional<Tank> findByIdAndFarmId(UUID id, UUID farmId);

    boolean existsByIdAndFarmId(UUID id, UUID farmId);
}
