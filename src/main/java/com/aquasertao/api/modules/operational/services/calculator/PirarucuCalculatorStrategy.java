package com.aquasertao.api.modules.operational.services.calculator;

import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Component
public class PirarucuCalculatorStrategy implements FeedCalculatorStrategy {

    private static final BigDecimal HARVEST_WEIGHT = new BigDecimal("8000");
    private static final BigDecimal DAILY_GAIN = new BigDecimal("20.0");

    @Override
    public String getSpeciesName() {
        return "Pirarucu";
    }

    @Override
    public CalculationResult calculate(int quantity, BigDecimal weightG, BigDecimal temperatureC) {
        BigDecimal biomassKg = BigDecimal.valueOf(quantity).multiply(weightG).divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP);

        BigDecimal feedRate;
        int treatments;
        String protein;
        String size;

        double w = weightG.doubleValue();

        // Feed Rate
        if (w <= 100) {
            feedRate = new BigDecimal("0.05");
        } else if (w <= 500) {
            feedRate = new BigDecimal("0.04");
        } else {
            feedRate = new BigDecimal("0.02");
        }

        // Protein
        if (w <= 100) {
            protein = "45%";
        } else {
            protein = "38%";
        }

        // Granulometry
        if (w <= 100) {
            size = "2,0 mm";
        } else {
            size = "6,0–8,0 mm";
        }

        // Treatments
        if (w <= 200) {
            treatments = 3;
        } else {
            treatments = 2;
        }

        // Apply temperature factor (generic rules)
        boolean tempAlert = false;
        if (temperatureC != null) {
            double temp = temperatureC.doubleValue();
            if (temp >= 33.0) {
                feedRate = BigDecimal.ZERO;
                tempAlert = true;
            } else if (temp < 16.0) {
                feedRate = BigDecimal.ZERO;
            }
        }

        BigDecimal dailyFeedKg = biomassKg.multiply(feedRate).setScale(4, RoundingMode.HALF_UP);
        BigDecimal feedPerTreatmentKg = dailyFeedKg.divide(BigDecimal.valueOf(treatments), 4, RoundingMode.HALF_UP);

        // Days to harvest
        int daysToHarvest = 0;
        if (weightG.compareTo(HARVEST_WEIGHT) < 0) {
            daysToHarvest = (int) Math.ceil(HARVEST_WEIGHT.subtract(weightG).divide(DAILY_GAIN, 2, RoundingMode.HALF_UP).doubleValue());
        }

        // Growth Simulation
        List<GrowthStep> simulation = new ArrayList<>();
        double currentWeight = w;
        int day = 0;
        while (currentWeight < HARVEST_WEIGHT.doubleValue()) {
            String phase;
            if (currentWeight < 100) {
                phase = "Alevino";
            } else if (currentWeight < 500) {
                phase = "Juvenil";
            } else if (currentWeight < HARVEST_WEIGHT.doubleValue() * 0.6) {
                phase = "Crescimento";
            } else {
                phase = "Terminação";
            }
            simulation.add(new GrowthStep(day, BigDecimal.valueOf(currentWeight).setScale(1, RoundingMode.HALF_UP), phase));
            currentWeight += DAILY_GAIN.doubleValue() * 15;
            day += 15;
            if (simulation.size() > 30) break;
        }
        simulation.add(new GrowthStep(day, HARVEST_WEIGHT, "Abate ✅"));

        return CalculationResult.builder()
                .biomassKg(biomassKg.setScale(2, RoundingMode.HALF_UP))
                .dailyFeedKg(dailyFeedKg.setScale(2, RoundingMode.HALF_UP))
                .feedPerTreatmentKg(feedPerTreatmentKg.setScale(2, RoundingMode.HALF_UP))
                .treatmentsPerDay(treatments)
                .proteinLevel(protein)
                .granulometry(size)
                .daysToHarvest(daysToHarvest)
                .tempAlert(tempAlert)
                .growthSimulation(simulation)
                .build();
    }
}
