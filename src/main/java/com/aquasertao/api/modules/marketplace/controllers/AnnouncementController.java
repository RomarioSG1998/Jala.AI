package com.aquasertao.api.modules.marketplace.controllers;

import com.aquasertao.api.modules.marketplace.dtos.AnnouncementRequestDTO;
import com.aquasertao.api.modules.marketplace.dtos.AnnouncementResponseDTO;
import com.aquasertao.api.modules.marketplace.services.AnnouncementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/announcements")
@RequiredArgsConstructor
public class AnnouncementController {

    private final AnnouncementService announcementService;

    /**
     * GET /api/announcements?category=ALEVINOS&location=PE
     * Lists all active announcements with optional filters.
     */
    @GetMapping
    public ResponseEntity<List<AnnouncementResponseDTO>> list(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String location) {
        return ResponseEntity.ok(announcementService.findAll(category, location));
    }

    /**
     * GET /api/announcements/my?farmId={uuid}
     * Lists announcements owned by this farm.
     */
    @GetMapping("/my")
    public ResponseEntity<List<AnnouncementResponseDTO>> myAnnouncements(@RequestParam UUID farmId) {
        return ResponseEntity.ok(announcementService.findByFarm(farmId));
    }

    /**
     * POST /api/announcements
     * Creates a new announcement.
     */
    @PostMapping
    public ResponseEntity<AnnouncementResponseDTO> create(@RequestBody AnnouncementRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(announcementService.create(dto));
    }

    /**
     * PUT /api/announcements/{id}?farmId={uuid}
     * Updates an existing announcement.
     */
    @PutMapping("/{id}")
    public ResponseEntity<AnnouncementResponseDTO> update(
            @PathVariable UUID id,
            @RequestParam UUID farmId,
            @RequestBody AnnouncementRequestDTO dto) {
        return ResponseEntity.ok(announcementService.update(id, farmId, dto));
    }

    /**
     * DELETE /api/announcements/{id}?farmId={uuid}
     * Soft-deletes (deactivates) an announcement.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deactivate(
            @PathVariable UUID id,
            @RequestParam UUID farmId) {
        announcementService.deactivate(id, farmId);
        return ResponseEntity.noContent().build();
    }
}
