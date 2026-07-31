package com.aquasertao.api.modules.billing.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckoutSessionRequestDTO {
    private UUID farmId;
    private UUID planId;
    private String successUrl;
    private String cancelUrl;
}
