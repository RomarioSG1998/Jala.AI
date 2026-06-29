package com.aquasertao.api.modules.operational.services.calculator;

import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Component
public class CarpaCalculatorStrategy implements FeedCalculatorStrategy {

    private static final BigDecimal HARVEST_WEIGHT = new BigDecimal("1000");
    private static final BigDecimal DAILY_GAIN = new BigDecimal("4.0");

    @Override
    public String getSpeciesName() {
        return "Carpa";
    }

    @Override
    public CalculationResult calculate(int quantity, BigDecimal weightG, BigDecimal temperatureC) {
        BigDecimal biomassKg = BigDecimal.valueOf(quantity).multiply(weightG).divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP);

        BigDecimal basePct;
        int treatments;
        String protein;
        String size;

        double w = weightG.doubleValue();

        if (w <= 0.0012) {
            basePct = new BigDecimal("0.136");
            treatments = 6;
            protein = "41%";
            size = "Em pó";
        } else if (w <= 0.012) {
            basePct = new BigDecimal("0.096");
            treatments = 6;
            protein = "41%";
            size = "Em pó";
        } else if (w <= 0.12) {
            basePct = new BigDecimal("0.08");
            treatments = 6;
            protein = "41%";
            size = "Em pó";
        } else if (w <= 0.8) {
            basePct = new BigDecimal("0.064");
            treatments = 4;
            protein = "41%";
            size = "Em pó";
        } else if (w <= 1.2) {
            basePct = new BigDecimal("0.04");
            treatments = 4;
            protein = "41%";
            size = "Em pó";
        } else if (w <= 1.5) {
            basePct = new BigDecimal("0.04");
            treatments = 4;
            protein = "34%";
            size = "1 a 2 mm";
        } else if (w <= 25) {
            basePct = new BigDecimal("0.016");
            treatments = 4;
            protein = "34%";
            size = "1 a 2 mm";
        } else if (w <= 55) {
            basePct = new BigDecimal("0.024");
            treatments = 3;
            protein = "34%";
            size = "2 a 4 mm";
        } else if (w <= 330) {
            basePct = new BigDecimal("0.024");
            treatments = 3;
            protein = "27%";
            size = "4 a 6 mm";
        } else if (w <= 410) {
            basePct = new BigDecimal("0.016");
            treatments = 3;
            protein = "27%";
            size = "4 a 6 mm";
        } else if (w <= 520) {
            basePct = new BigDecimal("0.016");
            treatments = 4;
            protein = "27%";
            size = "4 a 6 mm";
        } else {
            basePct = new BigDecimal("0.008");
            treatments = 3;
            protein = "27%";
            size = "6 a 8 mm";
        }

        // Apply temperature factor
        BigDecimal feedRate = basePct;
        boolean tempAlert = false;

        if (temperatureC != null) {
            double temp = temperatureC.doubleValue();
            if (temp >= 33.0) {
                feedRate = BigDecimal.ZERO;
                tempAlert = true;
            } else if (temp < 6.0) {
                feedRate = BigDecimal.ZERO;
            } else if (temp < 13.0) {
                feedRate = basePct.multiply(new BigDecimal("0.1875"));
            } else if (temp < 16.0) {
                feedRate = basePct.multiply(new BigDecimal("0.375"));
            } else if (temp < 20.0) {
                feedRate = basePct.multiply(new BigDecimal("0.625"));
            } else if (temp < 29.0) {
                feedRate = basePct.multiply(new BigDecimal("1.25"));
            } else { // 29 to 32
                feedRate = basePct;
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
            if (currentWeight < 30) {
                phase = "Alevino";
            } else if (currentWeight < 100) {
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
