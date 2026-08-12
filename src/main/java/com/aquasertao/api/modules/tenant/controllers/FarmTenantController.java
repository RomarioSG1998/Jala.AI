package com.aquasertao.api.modules.tenant.controllers;

import com.aquasertao.api.modules.tenant.dtos.FarmTenantRequestDTO;
import com.aquasertao.api.modules.tenant.dtos.FarmTenantResponseDTO;
import com.aquasertao.api.modules.tenant.services.FarmTenantService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Slf4j
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
            @PageableDefault(size = 100) Pageable pageable
    ) {
        try {
            Page<FarmTenantResponseDTO> responsePage = farmTenantService.getFarmsByOwnerId(ownerId, pageable);
            return ResponseEntity.ok(responsePage);
        } catch (Exception e) {
            log.error("Erro ao buscar fazendas por ownerId: {}", e.getMessage(), e);
            return ResponseEntity.ok(Page.empty());
        }
    }

    @GetMapping("/all")
    public ResponseEntity<Page<FarmTenantResponseDTO>> getAllFarms(@PageableDefault(size = 100) Pageable pageable) {
        try {
            return ResponseEntity.ok(farmTenantService.getAllFarms(pageable));
        } catch (Exception e) {
            log.error("Erro ao buscar todas as fazendas (/all): {}", e.getMessage(), e);
            return ResponseEntity.ok(Page.empty());
        }
    }

    @GetMapping
    public ResponseEntity<Page<FarmTenantResponseDTO>> getAllFarmsDefault(@PageableDefault(size = 100) Pageable pageable) {
        try {
            return ResponseEntity.ok(farmTenantService.getAllFarms(pageable));
        } catch (Exception e) {
            log.error("Erro ao buscar todas as fazendas (default): {}", e.getMessage(), e);
            return ResponseEntity.ok(Page.empty());
        }
    }
}
