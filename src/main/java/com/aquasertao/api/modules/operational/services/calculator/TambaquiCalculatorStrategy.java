package com.aquasertao.api.modules.operational.services.calculator;

import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Component
public class TambaquiCalculatorStrategy implements FeedCalculatorStrategy {

    private static final BigDecimal HARVEST_WEIGHT = new BigDecimal("1500");
    private static final BigDecimal DAILY_GAIN = new BigDecimal("4.5");

    @Override
    public String getSpeciesName() {
        return "Tambaqui";
    }

    @Override
    public CalculationResult calculate(int quantity, BigDecimal weightG, BigDecimal temperatureC) {
        BigDecimal biomassKg = BigDecimal.valueOf(quantity).multiply(weightG).divide(BigDecimal.valueOf(1000), 4, RoundingMode.HALF_UP);

        BigDecimal basePct;
        int treatments;
        String protein;
        String size;

        double w = weightG.doubleValue();
        int category; // 1: standard temp logic, 2: 25-70 temp logic, 3: > 1000 temp logic

        if (w <= 7) {
            basePct = new BigDecimal("0.1");
            treatments = 6;
            protein = "55%";
            size = "Em pó";
            category = 1;
        } else if (w <= 25) {
            basePct = new BigDecimal("0.0385");
            treatments = 4;
            protein = "40%";
            size = "1 a 2 mm";
            category = 1;
        } else if (w <= 70) {
            basePct = new BigDecimal("0.0295");
            treatments = 4;
            protein = "40%";
            size = "2 a 4 mm";
            category = 2;
        } else if (w <= 188) {
            basePct = new BigDecimal("0.021");
            treatments = 4;
            protein = "32%";
            size = "4 a 6 mm";
            category = 1;
        } else if (w <= 298) {
            basePct = new BigDecimal("0.013");
            treatments = 4;
            protein = "28%";
            size = "8 mm";
            category = 1;
        } else if (w <= 530) {
            basePct = new BigDecimal("0.0105");
            treatments = 3;
            protein = "28%";
            size = "8 mm";
            category = 1;
        } else if (w <= 1000) {
            basePct = new BigDecimal("0.0085");
            treatments = 2;
            protein = "28%";
            size = "8 mm";
            category = 1;
        } else {
            basePct = new BigDecimal("0.005");
            treatments = 2;
            protein = "28%";
            size = "6 a 8 mm";
            category = 3;
        }

        // Apply temperature factor
        BigDecimal feedRate = basePct;
        boolean tempAlert = false;

        if (temperatureC != null) {
            double temp = temperatureC.doubleValue();
            if (temp >= 33.0) {
                feedRate = BigDecimal.ZERO;
                tempAlert = true;
            } else {
                if (category == 1) {
                    if (temp < 16.0) {
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
                } else if (category == 2) {
                    if (temp < 6.0) {
                        feedRate = BigDecimal.ZERO;
                    } else if (temp < 13.0) {
                        feedRate = basePct.multiply(new BigDecimal("0.2"));
                    } else if (temp <= 15.0) {
                        feedRate = basePct;
                    } else if (temp <= 19.0) {
                        feedRate = basePct.multiply(new BigDecimal("1.7"));
                    } else if (temp <= 28.0) {
                        feedRate = basePct.multiply(new BigDecimal("2.0"));
                    } else { // 28 to 32
                        feedRate = basePct;
                    }
                } else { // category == 3
                    if (temp < 6.0) {
                        feedRate = BigDecimal.ZERO;
                    } else if (temp <= 12.0) {
                        feedRate = basePct.multiply(new BigDecimal("0.2"));
                    } else if (temp <= 15.0) {
                        feedRate = basePct;
                    } else if (temp <= 19.0) {
                        feedRate = basePct.multiply(new BigDecimal("1.7"));
                    } else if (temp <= 28.0) {
                        feedRate = basePct.multiply(new BigDecimal("2.0"));
                    } else { // 28 to 32
                        feedRate = basePct;
                    }
                }
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
