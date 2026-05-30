package com.aquasertao.api.modules.billing.services;

import com.aquasertao.api.modules.billing.models.SaaSPlan;
import com.aquasertao.api.modules.billing.repositories.SaasPlanRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class SaasPlanService {

    private final SaasPlanRepository repository;

    @Autowired
    public SaasPlanService(SaasPlanRepository repository) {
        this.repository = repository;
    }

    public List<SaaSPlan> findAllPlans() {
        return repository.findAll();
    }

    public SaaSPlan findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Plan not found with ID: " + id));
    }

    public SaaSPlan createPlan(SaaSPlan plan) {
        if (repository.existsByNameIgnoreCase(plan.getName())) {
            throw new RuntimeException("Plan with name '" + plan.getName() + "' already exists");
        }
        return repository.save(plan);
    }

    public SaaSPlan updatePlan(UUID id, SaaSPlan planDetails) {
        SaaSPlan plan = findById(id);
        
        // Only check name unique if the name changed
        if (!plan.getName().equalsIgnoreCase(planDetails.getName()) 
                && repository.existsByNameIgnoreCase(planDetails.getName())) {
            throw new RuntimeException("Plan with name '" + planDetails.getName() + "' already exists");
        }

        plan.setName(planDetails.getName());
        plan.setMaxTanks(planDetails.getMaxTanks());
        plan.setMaxUsers(planDetails.getMaxUsers());
        plan.setPriceMonthly(planDetails.getPriceMonthly());

        return repository.save(plan);
    }

    public void deletePlan(UUID id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Plan not found with ID: " + id);
        }
        try {
            repository.deleteById(id);
        } catch (Exception e) {
            throw new RuntimeException("Cannot delete plan because it is referenced by existing subscriptions");
        }
    }
}
