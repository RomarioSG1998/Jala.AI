package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.services.calculator.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.*;

class FeedCalculatorServiceTest {

    private FeedCalculatorService service;

    @BeforeEach
    void setUp() {
        service = new FeedCalculatorService(Arrays.asList(
                new TilapiaCalculatorStrategy(),
                new TambaquiCalculatorStrategy(),
                new CarpaCalculatorStrategy(),
                new PacuCalculatorStrategy(),
                new PirarucuCalculatorStrategy()
        ));
    }

    @Test
    void testSpeciesNormalizationAndSelection() {
        CalculationResult result1 = service.calculateFeed("Tilápia", 1000, new BigDecimal("10"), new BigDecimal("25"));
        CalculationResult result2 = service.calculateFeed("tilapia", 1000, new BigDecimal("10"), new BigDecimal("25"));
        CalculationResult result3 = service.calculateFeed("TILÁPIA", 1000, new BigDecimal("10"), new BigDecimal("25"));

        assertNotNull(result1);
        assertEquals(result1.getDailyFeedKg(), result2.getDailyFeedKg());
        assertEquals(result1.getDailyFeedKg(), result3.getDailyFeedKg());
    }

    @Test
    void testTilapiaLowTemperatureSuspension() {
        CalculationResult result = service.calculateFeed("Tilápia", 1000, new BigDecimal("50"), new BigDecimal("15"));
        assertEquals(BigDecimal.ZERO.setScale(2), result.getDailyFeedKg());
    }

    @Test
    void testTilapiaNormalCalculation() {
        // Tilapia, weight 50g, temp 25C
        // feed rate should be around 0.035 * 2.0 -> 0.070
        // biomass = 1000 * 50 / 1000 = 50 kg
        // daily feed = 50 * 0.070 = 3.50 kg
        CalculationResult result = service.calculateFeed("Tilápia", 1000, new BigDecimal("50"), new BigDecimal("25"));
        assertFalse(result.getTempAlert());
        assertEquals(new BigDecimal("3.50"), result.getDailyFeedKg());
        assertEquals(4, result.getTreatmentsPerDay());
    }

    @Test
    void testTambaquiHighTemperatureSuspension() {
        CalculationResult result = service.calculateFeed("Tambaqui", 1000, new BigDecimal("100"), new BigDecimal("33"));
        assertTrue(result.getTempAlert());
        assertEquals(BigDecimal.ZERO.setScale(2), result.getDailyFeedKg());
    }

    @Test
    void testTambaquiNormalCalculation() {
        // Tambaqui, weight 100g, temp 25C
        // category 1 (w=100 <= 188), base pct = 0.021
        // temp = 25 is in 23-29 range -> 2.0 scale -> feed rate = 0.021 * 2.0 = 0.042
        // biomass = 1000 * 100 / 1000 = 100 kg
        // daily feed = 100 * 0.042 = 4.2 kg
        CalculationResult result = service.calculateFeed("Tambaqui", 1000, new BigDecimal("100"), new BigDecimal("25"));
        assertEquals(new BigDecimal("4.20"), result.getDailyFeedKg());
    }

    @Test
    void testCarpaCalculation() {
        // Carpa, weight 100g, temp 22C
        // w <= 330 -> base pct = 0.024
        // temp = 22 is in 20-29 range -> 1.25 scale -> feed rate = 0.024 * 1.25 = 0.03
        // biomass = 1000 * 100 / 1000 = 100 kg
        // daily feed = 100 * 0.03 = 3.0 kg
        CalculationResult result = service.calculateFeed("Carpa", 1000, new BigDecimal("100"), new BigDecimal("22"));
        assertEquals(new BigDecimal("3.00"), result.getDailyFeedKg());
    }

    @Test
    void testPacuAdLibitumCalculation() {
        // Pacu, weight 5g, temp 25C -> "Á vontade"
        CalculationResult result = service.calculateFeed("Pacu", 1000, new BigDecimal("5"), new BigDecimal("25"));
        assertEquals(BigDecimal.ZERO.setScale(2), result.getDailyFeedKg());
        assertTrue(result.getGranulometry().contains("Á vontade"));
    }

    @Test
    void testPacuNormalCalculation() {
        // Pacu, weight 400g, temp 25C
        // 300 < w <= 500 -> base pct = 0.0409
        // temp = 25 is in 24-26 range -> feed rate = 0.0276
        // biomass = 1000 * 400 / 1000 = 400 kg
        // daily feed = 400 * 0.0276 = 11.04 kg
        CalculationResult result = service.calculateFeed("Pacu", 1000, new BigDecimal("400"), new BigDecimal("25"));
        assertEquals(new BigDecimal("11.04"), result.getDailyFeedKg());
    }
}
