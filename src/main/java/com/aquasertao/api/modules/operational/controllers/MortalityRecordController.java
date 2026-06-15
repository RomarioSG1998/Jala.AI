package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.MortalityRecordRequestDTO;
import com.aquasertao.api.modules.operational.dtos.MortalityRecordResponseDTO;
import com.aquasertao.api.modules.operational.services.MortalityRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/mortality")
@RequiredArgsConstructor
public class MortalityRecordController {

    private final MortalityRecordService mortalityRecordService;

    @PostMapping
    public ResponseEntity<MortalityRecordResponseDTO> createRecord(@RequestBody MortalityRecordRequestDTO requestDTO) {
        return ResponseEntity.ok(mortalityRecordService.createRecord(requestDTO));
    }

    @GetMapping("/tank/{tankId}")
    public ResponseEntity<List<MortalityRecordResponseDTO>> getRecordsByTank(
            @PathVariable UUID tankId,
            @RequestParam UUID farmId
    ) {
        return ResponseEntity.ok(mortalityRecordService.getRecordsByTank(tankId, farmId));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<MortalityRecordResponseDTO>> getRecordsByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        return ResponseEntity.ok(mortalityRecordService.getRecordsByFarmId(farmId, pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<MortalityRecordResponseDTO> getById(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        return ResponseEntity.ok(mortalityRecordService.getById(id, farmId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<MortalityRecordResponseDTO> updateRecord(
            @PathVariable UUID id,
            @RequestBody MortalityRecordRequestDTO requestDTO
    ) {
        return ResponseEntity.ok(mortalityRecordService.updateRecord(id, requestDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRecord(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        mortalityRecordService.deleteRecord(id, farmId);
        return ResponseEntity.noContent().build();
    }
}
