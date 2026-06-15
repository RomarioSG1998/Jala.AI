package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.BiometricsRecordRequestDTO;
import com.aquasertao.api.modules.operational.dtos.BiometricsRecordResponseDTO;
import com.aquasertao.api.modules.operational.services.BiometricsRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/biometrics")
@RequiredArgsConstructor
public class BiometricsRecordController {

    private final BiometricsRecordService biometricsRecordService;

    @PostMapping
    public ResponseEntity<BiometricsRecordResponseDTO> createBiometricsRecord(@RequestBody BiometricsRecordRequestDTO requestDTO) {
        return ResponseEntity.ok(biometricsRecordService.createBiometricsRecord(requestDTO));
    }

    @GetMapping("/tank/{tankId}")
    public ResponseEntity<List<BiometricsRecordResponseDTO>> getBiometricsByTank(
            @PathVariable UUID tankId,
            @RequestParam UUID farmId
    ) {
        return ResponseEntity.ok(biometricsRecordService.getBiometricsByTank(tankId, farmId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBiometricsRecord(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        biometricsRecordService.deleteBiometricsRecord(id, farmId);
        return ResponseEntity.noContent().build();
    }
}
