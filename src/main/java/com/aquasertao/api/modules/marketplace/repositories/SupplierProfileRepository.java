package com.aquasertao.api.modules.marketplace.repositories;

import com.aquasertao.api.modules.marketplace.models.SupplierProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SupplierProfileRepository extends JpaRepository<SupplierProfile, UUID> {
    Optional<SupplierProfile> findByFarmId(UUID farmId);
}
