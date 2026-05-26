package com.aquasertao.api.modules.tenant.dtos;

import lombok.Data;
import java.util.UUID;

@Data
public class EmployeeRequestDTO {
    private String name;
    private String email;
    private String password;
    private UUID farmId;
}
