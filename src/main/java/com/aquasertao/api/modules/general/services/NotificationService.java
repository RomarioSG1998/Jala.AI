package com.aquasertao.api.modules.general.services;

import com.aquasertao.api.modules.general.dtos.NotificationRequestDTO;
import com.aquasertao.api.modules.general.dtos.NotificationResponseDTO;
import com.aquasertao.api.modules.general.models.Notification;
import com.aquasertao.api.modules.general.repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public NotificationResponseDTO sendNotification(NotificationRequestDTO requestDTO) {
        Notification notification = Notification.builder()
                .targetUserId(requestDTO.getTargetUserId())
                .type(requestDTO.getType())
                .message(requestDTO.getMessage())
                .isRead(false)
                .build();

        Notification savedNotification = notificationRepository.save(notification);
        return mapToDTO(savedNotification);
    }

    public NotificationResponseDTO markAsRead(UUID notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new IllegalArgumentException("Notification not found"));
                
        notification.setIsRead(true);
        Notification updatedNotification = notificationRepository.save(notification);
        return mapToDTO(updatedNotification);
    }

    public Page<NotificationResponseDTO> getNotificationsByUser(UUID targetUserId, Pageable pageable) {
        Page<Notification> notificationPage = notificationRepository.findByTargetUserId(targetUserId, pageable);
        return notificationPage.map(this::mapToDTO);
    }

    private NotificationResponseDTO mapToDTO(Notification notification) {
        return NotificationResponseDTO.builder()
                .id(notification.getId())
                .targetUserId(notification.getTargetUserId())
                .type(notification.getType())
                .message(notification.getMessage())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt())
                .build();
    }
}
