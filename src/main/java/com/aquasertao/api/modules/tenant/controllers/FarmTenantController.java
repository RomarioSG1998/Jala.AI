package com.aquasertao.api.modules.tenant.controllers;

import com.aquasertao.api.modules.tenant.dtos.FarmTenantRequestDTO;
import com.aquasertao.api.modules.tenant.dtos.FarmTenantResponseDTO;
import com.aquasertao.api.modules.tenant.services.FarmTenantService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/tenants")
@RequiredArgsConstructor
public class FarmTenantController {

    private final FarmTenantService farmTenantService;

    @PostMapping
    public ResponseEntity<FarmTenantResponseDTO> createFarmTenant(@RequestBody FarmTenantRequestDTO requestDTO) {
        return ResponseEntity.ok(farmTenantService.createFarmTenant(requestDTO));
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<Page<FarmTenantResponseDTO>> getFarmsByOwnerId(
            @PathVariable UUID ownerId,
            Pageable pageable
    ) {
        Page<FarmTenantResponseDTO> responsePage = farmTenantService.getFarmsByOwnerId(ownerId, pageable);
        return ResponseEntity.ok(responsePage);
    }
}
