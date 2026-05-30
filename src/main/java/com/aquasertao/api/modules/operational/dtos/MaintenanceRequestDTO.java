package com.aquasertao.api.modules.operational.dtos;

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
public class MaintenanceRequestDTO {
    
    // Required to isolate data per Farm
    private UUID farmId;
    
    private UUID tankId;
    private String description;
    private String status;
    private LocalDate scheduledDate;
}
