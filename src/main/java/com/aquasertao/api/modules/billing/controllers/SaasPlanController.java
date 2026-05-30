package com.aquasertao.api.modules.billing.controllers;

import com.aquasertao.api.modules.billing.models.SaaSPlan;
import com.aquasertao.api.modules.billing.services.SaasPlanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/saas-plans")
public class SaasPlanController {

    private final SaasPlanService service;

    @Autowired
    public SaasPlanController(SaasPlanService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<SaaSPlan>> getAllPlans() {
        List<SaaSPlan> plans = service.findAllPlans();
        return ResponseEntity.ok(plans);
    }

    @GetMapping("/{id}")
    public ResponseEntity<SaaSPlan> getPlanById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PostMapping
    public ResponseEntity<SaaSPlan> createPlan(@RequestBody SaaSPlan plan) {
        return ResponseEntity.ok(service.createPlan(plan));
    }

    @PutMapping("/{id}")
    public ResponseEntity<SaaSPlan> updatePlan(@PathVariable UUID id, @RequestBody SaaSPlan plan) {
        return ResponseEntity.ok(service.updatePlan(id, plan));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlan(@PathVariable UUID id) {
        service.deletePlan(id);
        return ResponseEntity.noContent().build();
    }
}
