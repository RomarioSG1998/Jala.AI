package com.aquasertao.api.modules.general.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ApprovalRequestReqDTO {
    private UUID farmId;
    private UUID requesterId;
    private String requestedAction;
}
