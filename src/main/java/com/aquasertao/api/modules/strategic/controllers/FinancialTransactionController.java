package com.aquasertao.api.modules.strategic.controllers;

import com.aquasertao.api.modules.strategic.dtos.FinancialTransactionRequestDTO;
import com.aquasertao.api.modules.strategic.dtos.FinancialTransactionResponseDTO;
import com.aquasertao.api.modules.strategic.services.FinancialTransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/finances")
@RequiredArgsConstructor
public class FinancialTransactionController {

    private final FinancialTransactionService financialTransactionService;

    @PostMapping
    public ResponseEntity<FinancialTransactionResponseDTO> createTransaction(@RequestBody FinancialTransactionRequestDTO requestDTO) {
        return ResponseEntity.ok(financialTransactionService.createTransaction(requestDTO));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<FinancialTransactionResponseDTO>> getTransactionsByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        Page<FinancialTransactionResponseDTO> responsePage = financialTransactionService.getTransactionsByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTransaction(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        financialTransactionService.deleteTransaction(id, farmId);
        return ResponseEntity.noContent().build();
    }
}
