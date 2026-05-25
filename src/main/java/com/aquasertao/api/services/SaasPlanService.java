package com.aquasertao.api.services;

import com.aquasertao.api.models.SaasPlan;
import com.aquasertao.api.repositories.SaasPlanRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SaasPlanService {

    private final SaasPlanRepository repository;

    @Autowired
    public SaasPlanService(SaasPlanRepository repository) {
        this.repository = repository;
    }

    public List<SaasPlan> findAllPlans() {
        return repository.findAll();
    }
}
