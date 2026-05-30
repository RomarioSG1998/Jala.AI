package com.aquasertao.api.modules.general.dtos;

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
public class ApprovalRequestResDTO {
    private UUID id;
    private UUID farmId;
    private UUID requesterId;
    private String requestedAction;
    private String status;
    private LocalDateTime requestDate;
}
