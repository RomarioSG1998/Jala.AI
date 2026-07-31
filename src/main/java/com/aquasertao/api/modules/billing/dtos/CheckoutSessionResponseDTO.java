package com.aquasertao.api.modules.billing.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckoutSessionResponseDTO {
    private String checkoutUrl;
    private String sessionId;
}
