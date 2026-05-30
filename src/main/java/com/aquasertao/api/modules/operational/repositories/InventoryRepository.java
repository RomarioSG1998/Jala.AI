package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.Inventory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface InventoryRepository extends JpaRepository<Inventory, UUID> {
    
    // Strict Tenant Isolation + Pagination
    Page<Inventory> findByFarmId(UUID farmId, Pageable pageable);

    java.util.Optional<Inventory> findByIdAndFarmId(UUID id, UUID farmId);

    boolean existsByIdAndFarmId(UUID id, UUID farmId);
}
