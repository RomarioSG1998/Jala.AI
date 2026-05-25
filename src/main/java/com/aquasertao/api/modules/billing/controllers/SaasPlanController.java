package com.aquasertao.api.modules.billing.controllers;

import com.aquasertao.api.modules.billing.models.SaasPlan;
import com.aquasertao.api.modules.billing.services.SaasPlanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/saas-plans")
public class SaasPlanController {

    private final SaasPlanService service;

    @Autowired
    public SaasPlanController(SaasPlanService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<SaasPlan>> getAllPlans() {
        List<SaasPlan> plans = service.findAllPlans();
        return ResponseEntity.ok(plans);
    }
}
