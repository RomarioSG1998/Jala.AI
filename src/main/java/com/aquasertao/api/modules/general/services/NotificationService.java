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

import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    @Transactional
    public NotificationResponseDTO sendNotification(NotificationRequestDTO requestDTO) {
        Notification notification = Notification.builder()
                .targetUserId(requestDTO.getTargetUserId())
                .title(requestDTO.getTitle() != null ? requestDTO.getTitle() : formatTitleFromType(requestDTO.getType()))
                .type(requestDTO.getType() != null ? requestDTO.getType() : "SYSTEM")
                .message(requestDTO.getMessage())
                .isRead(false)
                .build();

        Notification savedNotification = notificationRepository.save(notification);
        return mapToDTO(savedNotification);
    }

    @Transactional
    public void createNotification(UUID targetUserId, String title, String type, String message) {
        if (targetUserId == null) return;
        Notification notification = Notification.builder()
                .targetUserId(targetUserId)
                .title(title)
                .type(type)
                .message(message)
                .isRead(false)
                .build();
        notificationRepository.save(notification);
    }

    @Transactional
    public NotificationResponseDTO markAsRead(UUID notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new IllegalArgumentException("Notificação não encontrada."));
                
        notification.setIsRead(true);
        Notification updatedNotification = notificationRepository.save(notification);
        return mapToDTO(updatedNotification);
    }

    @Transactional
    public void markAllAsRead(UUID targetUserId) {
        List<Notification> unread = notificationRepository.findByTargetUserIdAndIsReadFalse(targetUserId);
        for (Notification n : unread) {
            n.setIsRead(true);
        }
        notificationRepository.saveAll(unread);
    }

    @Transactional
    public void deleteNotification(UUID notificationId, UUID targetUserId) {
        notificationRepository.deleteByIdAndTargetUserId(notificationId, targetUserId);
    }

    @Transactional(readOnly = true)
    public List<NotificationResponseDTO> getMyNotifications(UUID targetUserId) {
        return notificationRepository.findByTargetUserIdOrderByCreatedAtDesc(targetUserId)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<NotificationResponseDTO> getNotificationsByUser(UUID targetUserId, Pageable pageable) {
        Page<Notification> notificationPage = notificationRepository.findByTargetUserId(targetUserId, pageable);
        return notificationPage.map(this::mapToDTO);
    }

    private NotificationResponseDTO mapToDTO(Notification notification) {
        String title = notification.getTitle();
        if (title == null || title.isBlank()) {
            title = formatTitleFromType(notification.getType());
        }
        return NotificationResponseDTO.builder()
                .id(notification.getId())
                .targetUserId(notification.getTargetUserId())
                .title(title)
                .type(notification.getType())
                .message(notification.getMessage())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt())
                .build();
    }

    private String formatTitleFromType(String type) {
        if (type == null) return "Notificação do Sistema";
        switch (type.toUpperCase()) {
            case "SYSTEM": return "Aviso do Sistema";
            case "TENANT_REGISTERED": return "Novo Cliente Cadastrado";
            case "SUPPLIER_APPROVED": return "Fornecedor Aprovado";
            case "WATER_QUALITY_ALERT": return "Alerta de Qualidade da Água";
            case "MAINTENANCE": return "Alerta de Manutenção";
            case "USER_STATUS": return "Status da Conta Atualizado";
            default: return "Notificação " + type;
        }
    }
}
