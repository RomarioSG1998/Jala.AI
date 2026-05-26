package com.aquasertao.api.modules.strategic.services;

import com.aquasertao.api.modules.strategic.dtos.FinancialTransactionRequestDTO;
import com.aquasertao.api.modules.strategic.dtos.FinancialTransactionResponseDTO;
import com.aquasertao.api.modules.strategic.models.FinancialTransaction;
import com.aquasertao.api.modules.strategic.repositories.FinancialTransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FinancialTransactionService {

    private final FinancialTransactionRepository financialTransactionRepository;

    public FinancialTransactionResponseDTO createTransaction(FinancialTransactionRequestDTO requestDTO) {
        FinancialTransaction transaction = FinancialTransaction.builder()
                .farmId(requestDTO.getFarmId())
                .type(requestDTO.getType())
                .amount(requestDTO.getAmount())
                .build();

        FinancialTransaction saved = financialTransactionRepository.save(transaction);
        return mapToDTO(saved);
    }

    public Page<FinancialTransactionResponseDTO> getTransactionsByFarmId(UUID farmId, Pageable pageable) {
        Page<FinancialTransaction> transactionPage = financialTransactionRepository.findByFarmId(farmId, pageable);
        return transactionPage.map(this::mapToDTO);
    }

    public void deleteTransaction(UUID id, UUID farmId) {
        if (!financialTransactionRepository.existsByIdAndFarmId(id, farmId)) {
            throw new IllegalArgumentException("Financial transaction not found or access denied");
        }
        financialTransactionRepository.deleteById(id);
    }

    private FinancialTransactionResponseDTO mapToDTO(FinancialTransaction transaction) {
        return FinancialTransactionResponseDTO.builder()
                .id(transaction.getId())
                .farmId(transaction.getFarmId())
                .type(transaction.getType())
                .amount(transaction.getAmount())
                .transactionDate(transaction.getTransactionDate())
                .build();
    }
}
