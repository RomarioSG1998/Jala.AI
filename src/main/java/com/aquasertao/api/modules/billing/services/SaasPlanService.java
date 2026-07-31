package com.aquasertao.api.modules.billing.services;

import com.aquasertao.api.modules.billing.models.SaaSPlan;
import com.aquasertao.api.modules.billing.repositories.SaasPlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SaasPlanService {

    private final SaasPlanRepository repository;
    private final StripeService stripeService;

    public List<SaaSPlan> findAllPlans() {
        return repository.findAll();
    }

    public SaaSPlan findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Plano não encontrado com ID: " + id));
    }

    public SaaSPlan createPlan(SaaSPlan plan) {
        if (repository.existsByNameIgnoreCase(plan.getName())) {
            throw new RuntimeException("Um plano com o nome '" + plan.getName() + "' já existe.");
        }
        
        // Sincronizar com o Stripe em tempo real
        plan = stripeService.syncPlanWithStripe(plan);
        return repository.save(plan);
    }

    public SaaSPlan updatePlan(UUID id, SaaSPlan planDetails) {
        SaaSPlan plan = findById(id);
        
        if (!plan.getName().equalsIgnoreCase(planDetails.getName()) 
                && repository.existsByNameIgnoreCase(planDetails.getName())) {
            throw new RuntimeException("Um plano com o nome '" + planDetails.getName() + "' já existe.");
        }

        plan.setName(planDetails.getName());
        plan.setMaxTanks(planDetails.getMaxTanks());
        plan.setMaxUsers(planDetails.getMaxUsers());
        plan.setPriceMonthly(planDetails.getPriceMonthly());
        if (planDetails.getDescription() != null) {
            plan.setDescription(planDetails.getDescription());
        }
        if (planDetails.getActive() != null) {
            plan.setActive(planDetails.getActive());
        }

        // Sincronizar modificações com o Stripe em tempo real
        plan = stripeService.syncPlanWithStripe(plan);
        return repository.save(plan);
    }

    public void deletePlan(UUID id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Plano não encontrado com ID: " + id);
        }
        try {
            repository.deleteById(id);
        } catch (Exception e) {
            throw new RuntimeException("Não é possível excluir o plano pois há assinaturas associadas.");
        }
    }
}
