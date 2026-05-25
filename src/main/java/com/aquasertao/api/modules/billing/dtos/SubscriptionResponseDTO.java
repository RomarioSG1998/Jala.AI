package com.aquasertao.api.modules.billing.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SubscriptionResponseDTO {
    private UUID id;
    private UUID farmId;
    private UUID planId;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;
}
