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

import com.aquasertao.api.modules.core.models.GlobalUser;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/me")
    public ResponseEntity<List<NotificationResponseDTO>> getMyNotifications(
            @AuthenticationPrincipal GlobalUser currentUser
    ) {
        if (currentUser == null) {
            return ResponseEntity.status(401).build();
        }
        return ResponseEntity.ok(notificationService.getMyNotifications(currentUser.getId()));
    }

    @PutMapping("/me/read-all")
    public ResponseEntity<Void> markAllAsRead(
            @AuthenticationPrincipal GlobalUser currentUser
    ) {
        if (currentUser != null) {
            notificationService.markAllAsRead(currentUser.getId());
        }
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{notificationId}")
    public ResponseEntity<Void> deleteNotification(
            @PathVariable UUID notificationId,
            @AuthenticationPrincipal GlobalUser currentUser
    ) {
        if (currentUser != null) {
            notificationService.deleteNotification(notificationId, currentUser.getId());
        }
        return ResponseEntity.noContent().build();
    }

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
