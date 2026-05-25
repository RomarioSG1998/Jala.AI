package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.dtos.FeedingRecordRequestDTO;
import com.aquasertao.api.modules.operational.dtos.FeedingRecordResponseDTO;
import com.aquasertao.api.modules.operational.services.FeedingRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/feeding-records")
@RequiredArgsConstructor
public class FeedingRecordController {

    private final FeedingRecordService feedingRecordService;

    @PostMapping
    public ResponseEntity<FeedingRecordResponseDTO> createFeedingRecord(@RequestBody FeedingRecordRequestDTO requestDTO) {
        return ResponseEntity.ok(feedingRecordService.createFeedingRecord(requestDTO));
    }

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<Page<FeedingRecordResponseDTO>> getFeedingRecordsByFarmId(
            @PathVariable UUID farmId,
            Pageable pageable
    ) {
        Page<FeedingRecordResponseDTO> responsePage = feedingRecordService.getFeedingRecordsByFarmId(farmId, pageable);
        return ResponseEntity.ok(responsePage);
    }
    @GetMapping("/{id}")
    public ResponseEntity<FeedingRecordResponseDTO> getFeedingRecordById(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        return ResponseEntity.ok(feedingRecordService.getById(id, farmId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<FeedingRecordResponseDTO> updateFeedingRecord(
            @PathVariable UUID id,
            @RequestBody FeedingRecordRequestDTO requestDTO
    ) {
        return ResponseEntity.ok(feedingRecordService.updateFeedingRecord(id, requestDTO));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFeedingRecord(
            @PathVariable UUID id,
            @RequestParam UUID farmId
    ) {
        feedingRecordService.deleteFeedingRecord(id, farmId);
        return ResponseEntity.noContent().build();
    }
}
