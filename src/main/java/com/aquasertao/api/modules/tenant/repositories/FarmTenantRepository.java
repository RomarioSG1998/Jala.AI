package com.aquasertao.api.modules.tenant.repositories;

import com.aquasertao.api.modules.tenant.models.FarmTenant;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface FarmTenantRepository extends JpaRepository<FarmTenant, UUID> {
    
    // Allow fetching all farms for a specific owner
    Page<FarmTenant> findByOwnerId(UUID ownerId, Pageable pageable);
}
