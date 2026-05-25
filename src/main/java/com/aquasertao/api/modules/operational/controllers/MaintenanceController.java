package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.MaintenanceRequestDTO;
import com.aquasertao.api.modules.operational.dtos.MaintenanceResponseDTO;
import com.aquasertao.api.modules.operational.services.MaintenanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/maintenance")
@RequiredArgsConstructor
public class MaintenanceController {

    private final MaintenanceService maintenanceService;

    @PostMapping
    public ResponseEntity<MaintenanceResponseDTO> logMaintenance(@RequestBody MaintenanceRequestDTO requestDTO) {
        return ResponseEntity.ok(maintenanceService.logMaintenance(requestDTO));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<MaintenanceResponseDTO>> getMaintenanceByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        Page<MaintenanceResponseDTO> responsePage = maintenanceService.getMaintenanceByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }
}
