package com.aquasertao.api.modules.billing.repositories;

import com.aquasertao.api.modules.billing.models.Subscription;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {
    
    // Find active subscriptions for a farm
    Page<Subscription> findByFarmId(UUID farmId, Pageable pageable);
    
    // Check if a farm has an active subscription
    Optional<Subscription> findByFarmIdAndStatus(UUID farmId, String status);
}
