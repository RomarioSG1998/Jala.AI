package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.InventoryRequestDTO;
import com.aquasertao.api.modules.operational.dtos.InventoryResponseDTO;
import com.aquasertao.api.modules.operational.services.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    @PostMapping
    public ResponseEntity<InventoryResponseDTO> createInventoryItem(@RequestBody InventoryRequestDTO requestDTO) {
        return ResponseEntity.ok(inventoryService.createInventoryItem(requestDTO));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<InventoryResponseDTO>> getInventoryByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        // Spring automatically resolves ?page=0&size=10 into the Pageable object
        Page<InventoryResponseDTO> responsePage = inventoryService.getInventoryByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }
}
