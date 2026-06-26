package com.aquasertao.api.modules.marketplace.dtos;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class AnnouncementResponseDTO {
    private UUID id;
    private UUID farmId;
    private String category;
    private String title;
    private String description;
    private BigDecimal price;
    private String sellerName;
    private String sellerPhone;
    private String sellerLocation;
    private String imageUrl;
    private Boolean active;
    private LocalDateTime createdAt;
}
