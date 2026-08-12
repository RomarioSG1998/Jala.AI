package com.aquasertao.api.modules.tenant.dtos;

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
public class FarmTenantResponseDTO {
    private UUID id;
    private String name;
    private String cnpj;
    private UUID ownerId;
    private String ownerName;
    private String ownerEmail;
    private Boolean userActive;
    private LocalDateTime createdAt;
}
