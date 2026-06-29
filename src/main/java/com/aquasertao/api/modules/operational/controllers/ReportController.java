package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.ReportSummaryDTO;
import com.aquasertao.api.modules.operational.services.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    /**
     * GET /api/reports/summary?farmId={uuid}
     * Returns aggregated report data: growth, mortality, feeding and harvest forecasts.
     */
    @GetMapping("/summary")
    public ResponseEntity<ReportSummaryDTO> getSummary(@RequestParam UUID farmId) {
        return ResponseEntity.ok(reportService.generateReport(farmId));
    }

    /**
     * GET /api/reports/plan-limit?farmId={uuid}
     * Returns the max number of tanks allowed for this farm's plan.
     */
    @GetMapping("/plan-limit")
    public ResponseEntity<Map<String, Integer>> getPlanLimit(@RequestParam UUID farmId) {
        int max = reportService.getMaxTanksAllowed(farmId);
        return ResponseEntity.ok(Map.of("maxTanks", max));
    }
}
