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
public class SubscriptionDetailsDTO {
    private UUID subscriptionId;
    private UUID farmId;
    private UUID planId;
    private String planName;
    private Integer maxTanks;
    private Integer maxUsers;
    private BigDecimal priceMonthly;
    private String status; // ACTIVE, PENDING_PAYMENT, CANCELLED, FREE
    private String startDate;
    private String endDate;
    private String nextBillingDate;
    private String stripeCustomerId;
    private String stripeSubscriptionId;
    private String paymentMethodType;
    private String cardBrand;
    private String cardLast4;
    private Boolean cancelAtPeriodEnd;
}
