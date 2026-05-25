package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.TankRequestDTO;
import com.aquasertao.api.modules.operational.dtos.TankResponseDTO;
import com.aquasertao.api.modules.operational.services.TankService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/tanks")
@RequiredArgsConstructor
public class TankController {

    private final TankService tankService;

    @PostMapping
    public ResponseEntity<TankResponseDTO> createTank(@RequestBody TankRequestDTO requestDTO) {
        return ResponseEntity.ok(tankService.createTank(requestDTO));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<TankResponseDTO>> getTanksByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        // Spring automatically resolves ?page=0&size=10 into the Pageable object
        Page<TankResponseDTO> responsePage = tankService.getTanksByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }
}
