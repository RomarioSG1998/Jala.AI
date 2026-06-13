package com.aquasertao.api.modules.general.listeners;

import com.aquasertao.api.modules.core.config.RabbitMQConfig;
import com.aquasertao.api.modules.general.events.SupplierApprovedEvent;
import com.aquasertao.api.modules.general.models.Notification;
import com.aquasertao.api.modules.general.repositories.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@RequiredArgsConstructor
@Slf4j
public class SupplierApprovedEventListener {

    private final NotificationRepository notificationRepository;

    @RabbitListener(queues = RabbitMQConfig.QUEUE_NAME)
    public void handleSupplierApproved(SupplierApprovedEvent event) {
        log.info("Received SupplierApprovedEvent for supplier: {}", event.getCompanyName());

        // Create a system notification for the SuperSaaS Admin
        Notification notification = Notification.builder()
                .targetUserId(UUID.fromString("11111111-1111-1111-1111-111111111111")) // SaaS Admin ID from seeds
                .type("SUPPLIER_APPROVED")
                .message("O fornecedor nacional " + event.getCompanyName() + " (CNPJ: " + event.getCnpj() + ") foi aprovado e está disponível no Marketplace.")
                .isRead(false)
                .build();

        notificationRepository.save(notification);
        log.info("Notification created for SaaS Admin for supplier: {}", event.getCompanyName());
    }
}
