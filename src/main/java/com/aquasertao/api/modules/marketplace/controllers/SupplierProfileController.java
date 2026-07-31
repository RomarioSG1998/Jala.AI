package com.aquasertao.api.modules.marketplace.controllers;

import com.aquasertao.api.modules.marketplace.dtos.SupplierProfileDTO;
import com.aquasertao.api.modules.marketplace.services.SupplierProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/marketplace/suppliers")
@RequiredArgsConstructor
public class SupplierProfileController {

    private final SupplierProfileService supplierProfileService;

    @PostMapping("/register")
    public ResponseEntity<SupplierProfileDTO> registerOrUpdate(@RequestBody SupplierProfileDTO dto) {
        return ResponseEntity.ok(supplierProfileService.registerOrUpdateProfile(dto));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<SupplierProfileDTO> getProfileByFarmId(@PathVariable UUID farmId) {
        SupplierProfileDTO profile = supplierProfileService.getProfileByFarmId(farmId);
        if (profile == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(profile);
    }
}
