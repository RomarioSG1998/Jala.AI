package com.aquasertao.api.modules.operational.services.calculator;

import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Component
public class TilapiaCalculatorStrategy implements FeedCalculatorStrategy {

    private static final BigDecimal HARVEST_WEIGHT = new BigDecimal("900");
    private static final BigDecimal DAILY_GAIN = new BigDecimal("3.5");

    @Override
    public String getSpeciesName() {
        return "Tilapia";
    }

    @Override
    public CalculationResult calculate(int quantity, BigDecimal weightG, BigDecimal temperatureC) {
        BigDecimal biomassKg = BigDecimal.valueOf(quantity).multiply(weightG).divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP);
        
        // Find base parameters
        BigDecimal basePct;
        int treatments;
        String protein;
        String size;

        double w = weightG.doubleValue();
        if (w <= 5) {
            basePct = new BigDecimal("0.10");
            treatments = 6;
            protein = "40%";
            size = "Em pó";
        } else if (w <= 10) {
            basePct = new BigDecimal("0.075");
            treatments = 4;
            protein = "36%";
            size = "1 a 2 mm";
        } else if (w <= 20) {
            basePct = new BigDecimal("0.05");
            treatments = 4;
            protein = "36%";
            size = "1 a 2 mm";
        } else if (w <= 50) {
            basePct = new BigDecimal("0.035");
            treatments = 4;
            protein = "36%";
            size = "2 a 4 mm";
        } else if (w <= 75) {
            basePct = new BigDecimal("0.025");
            treatments = 4;
            protein = "32%";
            size = "2 a 4 mm";
        } else if (w <= 100) {
            basePct = new BigDecimal("0.02");
            treatments = 4;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 125) {
            basePct = new BigDecimal("0.0175");
            treatments = 4;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 150) {
            basePct = new BigDecimal("0.015");
            treatments = 4;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 175) {
            basePct = new BigDecimal("0.013");
            treatments = 4;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 200) {
            basePct = new BigDecimal("0.0125");
            treatments = 3;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 225) {
            basePct = new BigDecimal("0.0115");
            treatments = 3;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 250) {
            basePct = new BigDecimal("0.011");
            treatments = 3;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 275) {
            basePct = new BigDecimal("0.0105");
            treatments = 3;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 300) {
            basePct = new BigDecimal("0.01");
            treatments = 3;
            protein = "32%";
            size = "4 a 6 mm";
        } else if (w <= 325) {
            basePct = new BigDecimal("0.0095");
            treatments = 3;
            protein = "28%";
            size = "4 a 6 mm";
        } else if (w <= 350) {
            basePct = new BigDecimal("0.009");
            treatments = 3;
            protein = "28%";
            size = "4 a 6 mm";
        } else if (w <= 375) {
            basePct = new BigDecimal("0.0085");
            treatments = 3;
            protein = "28%";
            size = "6 a 8 mm";
        } else if (w <= 400) {
            basePct = new BigDecimal("0.008");
            treatments = 3;
            protein = "28%";
            size = "6 a 8 mm";
        } else if (w <= 425) {
            basePct = new BigDecimal("0.00775");
            treatments = 3;
            protein = "28%";
            size = "6 a 8 mm";
        } else {
            basePct = new BigDecimal("0.0075");
            treatments = 3;
            protein = "28%";
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
            } else if (temp < 16.0) {
                feedRate = BigDecimal.ZERO;
            } else if (temp <= 18.0) {
                feedRate = basePct.multiply(new BigDecimal("0.2"));
            } else if (temp <= 19.9) {
                feedRate = basePct;
            } else if (temp <= 23.0) {
                feedRate = basePct.multiply(new BigDecimal("1.7"));
            } else if (temp <= 29.0) {
                feedRate = basePct.multiply(new BigDecimal("2.0"));
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
