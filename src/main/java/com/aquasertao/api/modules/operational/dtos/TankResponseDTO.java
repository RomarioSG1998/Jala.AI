package com.aquasertao.api.modules.operational.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class TankResponseDTO {
    private UUID id;
    private UUID farmId;
    private String name;
    private String fishSpecies;
    private Integer fishCapacity;
}
