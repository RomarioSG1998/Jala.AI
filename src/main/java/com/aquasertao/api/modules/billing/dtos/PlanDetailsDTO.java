package com.aquasertao.api.modules.billing.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PlanDetailsDTO {
    private UUID id;
    private String name;
    private Integer maxTanks;
    private Integer maxUsers;
    private BigDecimal priceMonthly;
    private String stripeProductId;
    private String stripePriceId;
    private String description;
    private Boolean active;
    private long activeSubscribers;
    private long totalSubscribers;
}
