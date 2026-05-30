package com.aquasertao.api.modules.operational.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class FeedingRecordResponseDTO {
    private UUID id;
    private UUID farmId;
    private UUID tankId;
    private UUID userId;
    private UUID feedId;
    private BigDecimal quantity;
    private LocalDateTime feedingTime;
}
