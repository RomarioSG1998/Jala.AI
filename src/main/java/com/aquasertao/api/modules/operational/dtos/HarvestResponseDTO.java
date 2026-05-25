package com.aquasertao.api.modules.operational.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class HarvestResponseDTO {
    private UUID id;
    private UUID farmId;
    private UUID tankId;
    private LocalDate date;
    private BigDecimal quantityKg;
    private String destination;
}
