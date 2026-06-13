package com.aquasertao.supplier.controllers;

import com.aquasertao.supplier.dtos.SupplierRequestDTO;
import com.aquasertao.supplier.dtos.SupplierResponseDTO;
import com.aquasertao.supplier.services.NationalSupplierService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/suppliers")
@RequiredArgsConstructor
public class NationalSupplierController {

    private final NationalSupplierService nationalSupplierService;

    @GetMapping
    public ResponseEntity<List<SupplierResponseDTO>> getAllSuppliers() {
        return ResponseEntity.ok(nationalSupplierService.getAllSuppliers());
    }

    @PostMapping
    public ResponseEntity<SupplierResponseDTO> createSupplier(@RequestBody SupplierRequestDTO requestDTO) {
        return ResponseEntity.ok(nationalSupplierService.createSupplier(requestDTO));
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<SupplierResponseDTO> approveSupplier(@PathVariable UUID id) {
        return ResponseEntity.ok(nationalSupplierService.approveSupplier(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSupplier(@PathVariable UUID id) {
        nationalSupplierService.deleteSupplier(id);
        return ResponseEntity.noContent().build();
    }
}
