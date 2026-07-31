package com.aquasertao.api.modules.billing.repositories;

import com.aquasertao.api.modules.billing.models.Subscription;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {
    
    Page<Subscription> findByFarmId(UUID farmId, Pageable pageable);
    Optional<Subscription> findByFarmIdAndStatus(UUID farmId, String status);
    List<Subscription> findByPlanId(UUID planId);
    long countByPlanIdAndStatus(UUID planId, String status);
    long countByStatus(String status);
    Optional<Subscription> findByStripeCheckoutSessionId(String checkoutSessionId);
    Optional<Subscription> findByStripeSubscriptionId(String stripeSubscriptionId);
    Optional<Subscription> findFirstByFarmIdOrderByStartDateDesc(UUID farmId);
}
