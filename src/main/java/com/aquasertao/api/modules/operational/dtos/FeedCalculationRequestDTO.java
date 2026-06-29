package com.aquasertao.api.modules.operational.dtos;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class FeedCalculationRequestDTO {
    private String species;
    private Integer quantity;
    private BigDecimal weightG;
    private BigDecimal temperatureC;
}
