package com.aquasertao.api.modules.operational.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class MortalityRecordResponseDTO {
    private UUID id;
    private UUID farmId;
    private UUID tankId;
    private Integer quantity;
    private String cause;
    private LocalDateTime recordDate;
}
