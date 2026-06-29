package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.services.calculator.CalculationResult;
import com.aquasertao.api.modules.operational.services.calculator.FeedCalculatorStrategy;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class FeedCalculatorService {

    private final Map<String, FeedCalculatorStrategy> strategyMap = new HashMap<>();

    public FeedCalculatorService(List<FeedCalculatorStrategy> strategies) {
        for (FeedCalculatorStrategy strategy : strategies) {
            String key = normalizeKey(strategy.getSpeciesName());
            strategyMap.put(key, strategy);
        }
    }

    public CalculationResult calculateFeed(String species, int quantity, BigDecimal weightG, BigDecimal temperatureC) {
        if (species == null || species.trim().isEmpty()) {
            throw new IllegalArgumentException("Species must be specified");
        }
        if (quantity <= 0) {
            throw new IllegalArgumentException("Quantity must be greater than zero");
        }
        if (weightG == null || weightG.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Weight must be greater than zero");
        }

        String normalized = normalizeKey(species);
        FeedCalculatorStrategy strategy = strategyMap.get(normalized);
        if (strategy == null) {
            throw new IllegalArgumentException("Unsupported species: " + species);
        }

        return strategy.calculate(quantity, weightG, temperatureC);
    }

    private String normalizeKey(String input) {
        if (input == null) return "";
        return Normalizer.normalize(input, Normalizer.Form.NFD)
                .replaceAll("[^\\p{ASCII}]", "")
                .toLowerCase()
                .trim();
    }
}
