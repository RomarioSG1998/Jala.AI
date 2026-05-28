package com.aquasertao.api.modules.tenant.repositories;

import com.aquasertao.api.modules.tenant.models.EmployeeModulePermission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EmployeeModulePermissionRepository
        extends JpaRepository<EmployeeModulePermission, EmployeeModulePermission.PermissionId> {

    List<EmployeeModulePermission> findByEmployeeIdAndFarmId(UUID employeeId, UUID farmId);

    Optional<EmployeeModulePermission> findByEmployeeIdAndFarmIdAndModuleName(
            UUID employeeId, UUID farmId, String moduleName);

    void deleteByEmployeeIdAndFarmId(UUID employeeId, UUID farmId);
}
