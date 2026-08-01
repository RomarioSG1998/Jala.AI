package com.aquasertao.api.modules.supplier.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SupplierResponseDTO {
    private UUID id;
    private String companyName;
    private String cnpj;
    private String supplyType;
    private Boolean isApproved;
}
