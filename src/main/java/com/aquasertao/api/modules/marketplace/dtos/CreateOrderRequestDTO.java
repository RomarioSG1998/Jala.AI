package com.aquasertao.api.modules.marketplace.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CreateOrderRequestDTO {
    private UUID announcementId;
    private UUID buyerFarmId;
    private Integer quantity;
    private String paymentMethod; // PIX | CARD
    private String buyerName;
    private String buyerPhone;
    private String deliveryAddress;
    private String deliveryCity;
    private String deliveryState;
    private String deliveryNotes;
}
