package com.aquasertao.api.modules.supplier.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SupplierRequestDTO {
    private String companyName;
    private String cnpj;
    private String supplyType;
}
