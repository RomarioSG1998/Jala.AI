package com.aquasertao.supplier.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SupplierApprovedEvent implements Serializable {
    private UUID supplierId;
    private String companyName;
    private String cnpj;
    private String supplyType;
}
