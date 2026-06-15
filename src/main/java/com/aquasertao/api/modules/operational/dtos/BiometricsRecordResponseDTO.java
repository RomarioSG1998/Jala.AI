package com.aquasertao.api.modules.operational.dtos;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BiometricsRecordResponseDTO {
    private UUID id;
    private UUID farmId;
    private UUID tankId;
    private Integer weightG;
    private LocalDate recordDate;
}
