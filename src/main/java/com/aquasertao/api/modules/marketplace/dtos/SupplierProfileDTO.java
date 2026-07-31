package com.aquasertao.api.modules.marketplace.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SupplierProfileDTO {
    private UUID id;
    private UUID farmId;
    private String companyName;
    private String documentNumber;
    private String stateRegistration;
    private String phone;
    private String email;
    private String address;
    private String city;
    private String state;
    private String pixKey;
    private String pixKeyType;
    private Boolean verified;
    private LocalDateTime createdAt;
}
