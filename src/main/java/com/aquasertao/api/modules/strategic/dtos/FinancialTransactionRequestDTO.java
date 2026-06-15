package com.aquasertao.api.modules.strategic.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class FinancialTransactionRequestDTO {

    private UUID farmId;
    private String type; // Income, Expense
    private BigDecimal amount;
    private String category;
    private String clientName;
    private String fishSpecies;
    private BigDecimal quantityKg;
    private java.time.LocalDateTime transactionDate;
}
