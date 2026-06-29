package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.CalculatorHistoryRequestDTO;
import com.aquasertao.api.modules.operational.models.CalculatorHistory;
import com.aquasertao.api.modules.operational.repositories.CalculatorHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/calculator")
@RequiredArgsConstructor
public class CalculatorController {

    private final CalculatorHistoryRepository calculatorHistoryRepository;
    private final com.aquasertao.api.modules.operational.services.FeedCalculatorService feedCalculatorService;

    /**
     * POST /api/calculator/calculate
     * Performs feed calculation using the strategy pattern.
     */
    @PostMapping("/calculate")
    public ResponseEntity<com.aquasertao.api.modules.operational.services.calculator.CalculationResult> calculate(@RequestBody com.aquasertao.api.modules.operational.dtos.FeedCalculationRequestDTO dto) {
        try {
            com.aquasertao.api.modules.operational.services.calculator.CalculationResult result = feedCalculatorService.calculateFeed(
                    dto.getSpecies(),
                    dto.getQuantity(),
                    dto.getWeightG(),
                    dto.getTemperatureC()
            );
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * POST /api/calculator/history
     * Save a calculator result to DB.
     */
    @PostMapping("/history")
    public ResponseEntity<CalculatorHistory> save(@RequestBody CalculatorHistoryRequestDTO dto) {
        CalculatorHistory entity = CalculatorHistory.builder()
                .farmId(dto.getFarmId())
                .tankId(dto.getTankId())
                .species(dto.getSpecies())
                .quantity(dto.getQuantity())
                .weightG(dto.getWeightG())
                .biomassKg(dto.getBiomassKg())
                .dailyFeedKg(dto.getDailyFeedKg())
                .feedPerTreatmentKg(dto.getFeedPerTreatmentKg())
                .treatmentsPerDay(dto.getTreatmentsPerDay())
                .proteinLevel(dto.getProteinLevel())
                .granulometry(dto.getGranulometry())
                .daysToHarvest(dto.getDaysToHarvest())
                .temperatureC(dto.getTemperatureC())
                .tempAlert(dto.getTempAlert())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED).body(calculatorHistoryRepository.save(entity));
    }

    /**
     * GET /api/calculator/history?farmId={uuid}
     * Get calculator history for a farm.
     */
    @GetMapping("/history")
    public ResponseEntity<List<CalculatorHistory>> getHistory(@RequestParam UUID farmId) {
        return ResponseEntity.ok(calculatorHistoryRepository.findByFarmIdOrderByCalculatedAtDesc(farmId));
    }
}
