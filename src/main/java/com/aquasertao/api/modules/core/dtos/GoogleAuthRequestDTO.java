package com.aquasertao.api.modules.core.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class GoogleAuthRequestDTO {
    private String idToken;
    private String email;
    private String name;
    private String photoUrl;
    private String accountType;
}
