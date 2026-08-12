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
public class NotificationResponseDTO {
    private UUID id;
    private UUID targetUserId;
    private String title;
    private String type;
    private String message;
    private Boolean isRead;
    private LocalDateTime createdAt;
}
