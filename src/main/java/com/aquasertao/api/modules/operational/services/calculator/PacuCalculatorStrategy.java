package com.aquasertao.api.modules.operational.services.calculator;

import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Component
public class PacuCalculatorStrategy implements FeedCalculatorStrategy {

    private static final BigDecimal HARVEST_WEIGHT = new BigDecimal("1200");
    private static final BigDecimal DAILY_GAIN = new BigDecimal("4.0");

    @Override
    public String getSpeciesName() {
        return "Pacu";
    }

    @Override
    public CalculationResult calculate(int quantity, BigDecimal weightG, BigDecimal temperatureC) {
        BigDecimal biomassKg = BigDecimal.valueOf(quantity).multiply(weightG).divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP);

        BigDecimal basePct = null; // null represents "Á vontade"
        int treatments;
        String protein;
        String size;

        double w = weightG.doubleValue();

        if (w <= 10) {
            basePct = null;
            treatments = 4;
            protein = "40 a 50%";
            size = "Farelada (em pó)";
        } else if (w <= 50) {
            basePct = null;
            treatments = 4;
            protein = "36 a 38%";
            size = "2,5 mm";
        } else if (w <= 100) {
            basePct = null;
            treatments = 4;
            protein = "28 a 32%";
            size = "3 a 4 mm";
        } else if (w <= 300) {
            basePct = new BigDecimal("0.0538");
            treatments = 4;
            protein = "28 a 32%";
            size = "3 a 4 mm";
        } else if (w <= 500) {
            basePct = new BigDecimal("0.0409");
            treatments = 3;
            protein = "28 a 32%";
            size = "6 mm";
        } else if (w <= 700) {
            basePct = new BigDecimal("0.0302");
            treatments = 3;
            protein = "28 a 32%";
            size = "6 mm";
        } else if (w <= 900) {
            basePct = new BigDecimal("0.0274");
            treatments = 2;
            protein = "28 a 32%";
            size = "6 mm";
        } else if (w <= 1100) {
            basePct = new BigDecimal("0.0201");
            treatments = 2;
            protein = "Até 28%";
            size = "6 mm";
        } else if (w <= 1300) {
            basePct = new BigDecimal("0.0184");
            treatments = 2;
            protein = "Até 28%";
            size = "6 mm";
        } else {
            basePct = new BigDecimal("0.0141");
            treatments = 2;
            protein = "Até 28%";
            size = "6 mm";
        }

        // Apply temperature factor
        BigDecimal feedRate = basePct;
        boolean tempAlert = false;
        boolean isAdLibitum = basePct == null;

        if (temperatureC != null) {
            double temp = temperatureC.doubleValue();
            if (temp >= 33.0) {
                feedRate = BigDecimal.ZERO;
                isAdLibitum = false;
                tempAlert = true;
            } else if (temp < 18.0) {
                feedRate = BigDecimal.ZERO;
                isAdLibitum = false;
            } else if (isAdLibitum) {
                // If it is "Á vontade" and temperature is normal, it stays "Á vontade"
                feedRate = null;
            } else {
                // Calculate feed rate based on temperature brackets
                if (w <= 300) {
                    if (temp <= 19.0) feedRate = new BigDecimal("0.0033");
                    else if (temp <= 20.0) feedRate = new BigDecimal("0.0111");
                    else if (temp <= 22.0) feedRate = new BigDecimal("0.0188");
                    else if (temp <= 24.0) feedRate = new BigDecimal("0.0288");
                    else if (temp <= 26.0) feedRate = new BigDecimal("0.0449");
                    else feedRate = new BigDecimal("0.0538");
                } else if (w <= 500) {
                    if (temp <= 19.0) feedRate = new BigDecimal("0.0015");
                    else if (temp <= 20.0) feedRate = new BigDecimal("0.0050");
                    else if (temp <= 22.0) feedRate = new BigDecimal("0.0077");
                    else if (temp <= 24.0) feedRate = new BigDecimal("0.0157");
                    else if (temp <= 26.0) feedRate = new BigDecimal("0.0276");
                    else feedRate = new BigDecimal("0.0409");
                } else if (w <= 700) {
                    if (temp <= 19.0) feedRate = new BigDecimal("0.0011");
                    else if (temp <= 20.0) feedRate = new BigDecimal("0.0036");
                    else if (temp <= 22.0) feedRate = new BigDecimal("0.0064");
                    else if (temp <= 24.0) feedRate = new BigDecimal("0.0088");
                    else if (temp <= 26.0) feedRate = new BigDecimal("0.0155");
                    else feedRate = new BigDecimal("0.0302");
                } else if (w <= 900) {
                    if (temp <= 19.0) feedRate = new BigDecimal("0.0014");
                    else if (temp <= 20.0) feedRate = new BigDecimal("0.0049");
                    else if (temp <= 22.0) feedRate = new BigDecimal("0.0091");
                    else if (temp <= 24.0) feedRate = new BigDecimal("0.0107");
                    else if (temp <= 26.0) feedRate = new BigDecimal("0.0154");
                    else feedRate = new BigDecimal("0.0274");
                } else if (w <= 1100) {
                    if (temp <= 19.0) feedRate = new BigDecimal("0.0010");
                    else if (temp <= 20.0) feedRate = new BigDecimal("0.0034");
                    else if (temp <= 22.0) feedRate = new BigDecimal("0.0064");
                    else if (temp <= 24.0) feedRate = new BigDecimal("0.0074");
                    else if (temp <= 26.0) feedRate = new BigDecimal("0.0104");
                    else feedRate = new BigDecimal("0.0201");
                } else if (w <= 1300) {
                    if (temp <= 19.0) feedRate = new BigDecimal("0.0008");
                    else if (temp <= 20.0) feedRate = new BigDecimal("0.0028");
                    else if (temp <= 22.0) feedRate = new BigDecimal("0.0050");
                    else if (temp <= 24.0) feedRate = new BigDecimal("0.0063");
                    else if (temp <= 26.0) feedRate = new BigDecimal("0.0092");
                    else feedRate = new BigDecimal("0.0184");
                } else {
                    if (temp <= 19.0) feedRate = new BigDecimal("0.0007");
                    else if (temp <= 20.0) feedRate = new BigDecimal("0.0023");
                    else if (temp <= 22.0) feedRate = new BigDecimal("0.0044");
                    else if (temp <= 24.0) feedRate = new BigDecimal("0.0064");
                    else if (temp <= 26.0) feedRate = new BigDecimal("0.0079");
                    else feedRate = new BigDecimal("0.0141");
                }
            }
        }

        BigDecimal dailyFeedKg = null;
        BigDecimal feedPerTreatmentKg = null;

        if (feedRate != null) {
            dailyFeedKg = biomassKg.multiply(feedRate).setScale(4, RoundingMode.HALF_UP);
            feedPerTreatmentKg = dailyFeedKg.divide(BigDecimal.valueOf(treatments), 4, RoundingMode.HALF_UP);
        } else if (isAdLibitum) {
            dailyFeedKg = BigDecimal.ZERO; // Use 0 to represent "Á vontade"
            feedPerTreatmentKg = BigDecimal.ZERO;
        }

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
                .dailyFeedKg(dailyFeedKg != null ? dailyFeedKg.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO)
                .feedPerTreatmentKg(feedPerTreatmentKg != null ? feedPerTreatmentKg.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO)
                .treatmentsPerDay(treatments)
                .proteinLevel(protein)
                .granulometry(isAdLibitum ? size + " (Á vontade)" : size)
                .daysToHarvest(daysToHarvest)
                .tempAlert(tempAlert)
                .growthSimulation(simulation)
                .build();
    }
}
