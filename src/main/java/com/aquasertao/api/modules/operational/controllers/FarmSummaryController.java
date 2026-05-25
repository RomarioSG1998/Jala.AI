package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.FarmSummaryDTO;
import com.aquasertao.api.modules.operational.services.FarmSummaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/farms")
@RequiredArgsConstructor
public class FarmSummaryController {

    private final FarmSummaryService farmSummaryService;

    @GetMapping("/{farmId}/summary")
    public ResponseEntity<FarmSummaryDTO> getFarmSummary(@PathVariable UUID farmId) {
        return ResponseEntity.ok(farmSummaryService.getFarmSummary(farmId));
    }
}
