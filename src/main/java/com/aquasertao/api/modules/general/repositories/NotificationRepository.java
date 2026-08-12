package com.aquasertao.api.modules.general.repositories;

import com.aquasertao.api.modules.general.models.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    
    // User-level Tenant Isolation
    Page<Notification> findByTargetUserId(UUID targetUserId, Pageable pageable);
    
    List<Notification> findByTargetUserIdOrderByCreatedAtDesc(UUID targetUserId);
    
    List<Notification> findByTargetUserIdAndIsReadFalse(UUID targetUserId);
    
    void deleteByIdAndTargetUserId(UUID id, UUID targetUserId);
}
