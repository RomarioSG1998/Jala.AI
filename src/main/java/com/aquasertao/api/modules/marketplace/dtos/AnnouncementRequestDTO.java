package com.aquasertao.api.modules.marketplace.dtos;

import lombok.Data;
import java.math.BigDecimal;
import java.util.UUID;

@Data
public class AnnouncementRequestDTO {
    private UUID farmId;
    private String category;   // ALEVINOS | RACAO | EQUIPAMENTOS
    private String title;
    private String description;
    private BigDecimal price;
    private String sellerName;
    private String sellerPhone;
    private String sellerLocation;
    private String imageUrl;
}
