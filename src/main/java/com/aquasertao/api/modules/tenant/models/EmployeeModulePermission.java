package com.aquasertao.api.modules.tenant.models;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;
import java.util.UUID;

@Entity
@Table(name = "employee_module_permission", schema = "auth_schema")
@IdClass(EmployeeModulePermission.PermissionId.class)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeModulePermission {

    @Id
    @Column(name = "employee_id")
    private UUID employeeId;

    @Id
    @Column(name = "farm_id")
    private UUID farmId;

    @Id
    @Column(name = "module_name")
    private String moduleName;

    @Column(name = "is_enabled", nullable = false)
    private boolean isEnabled;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PermissionId implements Serializable {
        private UUID employeeId;
        private UUID farmId;
        private String moduleName;
    }
}
