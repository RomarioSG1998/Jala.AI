package com.aquasertao.api.modules.tenant.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class FarmTenantRequestDTO {
    private String name;
    private String cnpj;
    private UUID ownerId;
}
