package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.WaterQualityRequestDTO;
import com.aquasertao.api.modules.operational.dtos.WaterQualityResponseDTO;
import com.aquasertao.api.modules.operational.services.WaterQualityService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/water-quality")
@RequiredArgsConstructor
public class WaterQualityController {

    private final WaterQualityService waterQualityService;

    @PostMapping
    public ResponseEntity<WaterQualityResponseDTO> logWaterQuality(@RequestBody WaterQualityRequestDTO requestDTO) {
        return ResponseEntity.ok(waterQualityService.logWaterQuality(requestDTO));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<WaterQualityResponseDTO>> getWaterQualityByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        Page<WaterQualityResponseDTO> responsePage = waterQualityService.getWaterQualityByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }
    @GetMapping("/{id}")
    public ResponseEntity<WaterQualityResponseDTO> getWaterQualityById(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        return ResponseEntity.ok(waterQualityService.getById(id, farmId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<WaterQualityResponseDTO> updateWaterQuality(
            @PathVariable UUID id,
            @RequestBody WaterQualityRequestDTO requestDTO
    ) {
        return ResponseEntity.ok(waterQualityService.updateWaterQuality(id, requestDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteWaterQuality(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        waterQualityService.deleteWaterQuality(id, farmId);
        return ResponseEntity.noContent().build();
    }
}
