package com.aquasertao.api.modules.general.repositories;

import com.aquasertao.api.modules.general.models.ApprovalRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ApprovalRequestRepository extends JpaRepository<ApprovalRequest, UUID> {
    
    // Strict Tenant Isolation + Pagination
    Page<ApprovalRequest> findByFarmId(UUID farmId, Pageable pageable);
}
