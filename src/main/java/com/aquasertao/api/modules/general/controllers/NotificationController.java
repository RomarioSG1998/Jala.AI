package com.aquasertao.api.modules.general.controllers;

import com.aquasertao.api.modules.general.dtos.NotificationRequestDTO;
import com.aquasertao.api.modules.general.dtos.NotificationResponseDTO;
import com.aquasertao.api.modules.general.services.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @PostMapping
    public ResponseEntity<NotificationResponseDTO> sendNotification(@RequestBody NotificationRequestDTO requestDTO) {
        return ResponseEntity.ok(notificationService.sendNotification(requestDTO));
    }

    @PutMapping("/{notificationId}/read")
    public ResponseEntity<NotificationResponseDTO> markAsRead(@PathVariable UUID notificationId) {
        return ResponseEntity.ok(notificationService.markAsRead(notificationId));
    }

    @GetMapping("/user/{targetUserId}")
    public ResponseEntity<Page<NotificationResponseDTO>> getNotificationsByUser(
            @PathVariable UUID targetUserId,
            Pageable pageable
    ) {
        Page<NotificationResponseDTO> responsePage = notificationService.getNotificationsByUser(targetUserId, pageable);
        return ResponseEntity.ok(responsePage);
    }
}
