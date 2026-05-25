package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.HarvestRequestDTO;
import com.aquasertao.api.modules.operational.dtos.HarvestResponseDTO;
import com.aquasertao.api.modules.operational.services.HarvestService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/harvests")
@RequiredArgsConstructor
public class HarvestController {

    private final HarvestService harvestService;

    @PostMapping
    public ResponseEntity<HarvestResponseDTO> logHarvest(@RequestBody HarvestRequestDTO requestDTO) {
        return ResponseEntity.ok(harvestService.logHarvest(requestDTO));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<HarvestResponseDTO>> getHarvestsByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        // Spring automatically resolves ?page=0&size=10 into the Pageable object
        Page<HarvestResponseDTO> responsePage = harvestService.getHarvestsByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }
}
