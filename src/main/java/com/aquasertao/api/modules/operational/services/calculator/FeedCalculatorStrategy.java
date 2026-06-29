package com.aquasertao.api.modules.operational.services.calculator;

import java.math.BigDecimal;

public interface FeedCalculatorStrategy {
    String getSpeciesName();
    CalculationResult calculate(int quantity, BigDecimal weightG, BigDecimal temperatureC);
}
