package com.aquasertao.api.modules.operational.services.calculator;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GrowthStep {
    private Integer day;
    private BigDecimal weightG;
    private String phase;
}
