package com.aquasertao.api.modules.billing.repositories;

import com.aquasertao.api.modules.billing.models.SaaSPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SaaSPlanRepository extends JpaRepository<SaaSPlan, UUID> {
    Optional<SaaSPlan> findByName(String name);
}
