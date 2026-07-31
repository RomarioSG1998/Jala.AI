package com.aquasertao.api.modules.tenant.controllers;

import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.tenant.dtos.EmployeeRequestDTO;
import com.aquasertao.api.modules.tenant.dtos.EmployeeResponseDTO;
import com.aquasertao.api.modules.tenant.models.EmployeeModulePermission;
import com.aquasertao.api.modules.tenant.models.UserFarmLink;
import com.aquasertao.api.modules.tenant.repositories.EmployeeModulePermissionRepository;
import com.aquasertao.api.modules.tenant.repositories.UserFarmLinkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.operational.services.TankService.PlanLimitExceededException;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
public class EmployeeController {

    // All modules a FIELD_OPERATOR can potentially access (owner manages these)
    public static final List<String> AVAILABLE_MODULES = List.of(
            "tanks", "water_quality", "inventory",
            "feeding_records", "harvests", "maintenance"
    );

    private final GlobalUserRepository globalUserRepository;
    private final UserFarmLinkRepository userFarmLinkRepository;
    private final EmployeeModulePermissionRepository permissionRepository;
    private final PasswordEncoder passwordEncoder;
    private final SubscriptionRepository subscriptionRepository;
    private final SaaSPlanRepository saasPlanRepository;

    // ── List employees ────────────────────────────────────────────────────────

    @GetMapping("/farm/{farmId}")
    public ResponseEntity<List<EmployeeResponseDTO>> getEmployeesByFarm(@PathVariable UUID farmId) {
        List<UserFarmLink> links = userFarmLinkRepository.findByFarmIdAndAccessRole(farmId, "FIELD_WORKER");

        List<EmployeeResponseDTO> employees = links.stream()
                .map(link -> globalUserRepository.findById(link.getUserId()).orElse(null))
                .filter(user -> user != null)
                .map(user -> EmployeeResponseDTO.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .email(user.getEmail())
                        .accountType(user.getAccountType())
                        .build())
                .collect(Collectors.toList());

        return ResponseEntity.ok(employees);
    }

    // ── Create employee ───────────────────────────────────────────────────────

    @PostMapping
    @Transactional
    public ResponseEntity<?> createEmployee(@RequestBody EmployeeRequestDTO requestDTO) {
        List<UserFarmLink> existingLinks = userFarmLinkRepository.findByFarmId(requestDTO.getFarmId());
        int maxUsersAllowed = subscriptionRepository.findByFarmIdAndStatus(requestDTO.getFarmId(), "ACTIVE")
                .map(sub -> saasPlanRepository.findById(sub.getPlanId())
                        .map(plan -> plan.getMaxUsers())
                        .orElse(2))
                .orElse(2);
        if (existingLinks.size() >= maxUsersAllowed) {
            throw new PlanLimitExceededException(maxUsersAllowed);
        }

        if (globalUserRepository.findByEmail(requestDTO.getEmail()).isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Email already registered.");
        }

        GlobalUser employee = GlobalUser.builder()
                .name(requestDTO.getName())
                .email(requestDTO.getEmail())
                .password(passwordEncoder.encode(requestDTO.getPassword()))
                .accountType("FIELD_OPERATOR")
                .createdAt(LocalDateTime.now())
                .build();

        GlobalUser savedEmployee = globalUserRepository.save(employee);

        UserFarmLink link = UserFarmLink.builder()
                .userId(savedEmployee.getId())
                .farmId(requestDTO.getFarmId())
                .accessRole("FIELD_WORKER")
                .build();

        userFarmLinkRepository.save(link);

        // Initialize ALL modules as enabled for the new employee
        initDefaultPermissions(savedEmployee.getId(), requestDTO.getFarmId());

        EmployeeResponseDTO response = EmployeeResponseDTO.builder()
                .id(savedEmployee.getId())
                .name(savedEmployee.getName())
                .email(savedEmployee.getEmail())
                .accountType(savedEmployee.getAccountType())
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    // ── Update employee ───────────────────────────────────────────────────────

    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<?> updateEmployee(@PathVariable UUID id, @RequestBody EmployeeRequestDTO requestDTO) {
        GlobalUser employee = globalUserRepository.findById(id).orElse(null);
        if (employee == null) {
            return ResponseEntity.notFound().build();
        }

        if (!employee.getEmail().equalsIgnoreCase(requestDTO.getEmail()) &&
                globalUserRepository.findByEmail(requestDTO.getEmail()).isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Email already registered.");
        }

        employee.setName(requestDTO.getName());
        employee.setEmail(requestDTO.getEmail());
        if (requestDTO.getPassword() != null && !requestDTO.getPassword().trim().isEmpty()) {
            employee.setPassword(passwordEncoder.encode(requestDTO.getPassword()));
        }

        GlobalUser savedEmployee = globalUserRepository.save(employee);

        return ResponseEntity.ok(EmployeeResponseDTO.builder()
                .id(savedEmployee.getId())
                .name(savedEmployee.getName())
                .email(savedEmployee.getEmail())
                .accountType(savedEmployee.getAccountType())
                .build());
    }

    // ── Delete employee ───────────────────────────────────────────────────────

    @DeleteMapping("/{id}/farm/{farmId}")
    @Transactional
    public ResponseEntity<Void> deleteEmployee(@PathVariable UUID id, @PathVariable UUID farmId) {
        UserFarmLink.UserFarmLinkId linkId = new UserFarmLink.UserFarmLinkId(id, farmId);
        if (!userFarmLinkRepository.existsById(linkId)) {
            return ResponseEntity.notFound().build();
        }
        globalUserRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // ── Module Permissions ────────────────────────────────────────────────────

    /**
     * GET /api/employees/{id}/farm/{farmId}/permissions
     * Returns all modules with their enabled status for the given employee.
     * If no record exists for a module, it is initialized as enabled.
     */
    @GetMapping("/{id}/farm/{farmId}/permissions")
    @Transactional
    public ResponseEntity<List<Map<String, Object>>> getPermissions(
            @PathVariable UUID id, @PathVariable UUID farmId) {

        List<EmployeeModulePermission> stored = permissionRepository.findByEmployeeIdAndFarmId(id, farmId);

        // Initialize any missing modules with default = true
        Set<String> existingModules = stored.stream()
                .map(EmployeeModulePermission::getModuleName)
                .collect(Collectors.toSet());

        List<EmployeeModulePermission> toSave = AVAILABLE_MODULES.stream()
                .filter(m -> !existingModules.contains(m))
                .map(m -> EmployeeModulePermission.builder()
                        .employeeId(id).farmId(farmId).moduleName(m).isEnabled(true).build())
                .collect(Collectors.toList());

        if (!toSave.isEmpty()) {
            permissionRepository.saveAll(toSave);
            stored = permissionRepository.findByEmployeeIdAndFarmId(id, farmId);
        }

        List<Map<String, Object>> result = stored.stream()
                .map(p -> Map.<String, Object>of(
                        "moduleName", p.getModuleName(),
                        "isEnabled", p.isEnabled()))
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    /**
     * PUT /api/employees/{id}/farm/{farmId}/permissions/{module}
     * Toggle the enabled status of a single module for the employee.
     * Body: { "isEnabled": true/false }
     */
    @PutMapping("/{id}/farm/{farmId}/permissions/{module}")
    @Transactional
    public ResponseEntity<Map<String, Object>> setPermission(
            @PathVariable UUID id,
            @PathVariable UUID farmId,
            @PathVariable String module,
            @RequestBody Map<String, Boolean> body) {

        if (!AVAILABLE_MODULES.contains(module)) {
            return ResponseEntity.badRequest().build();
        }

        boolean enabled = Boolean.TRUE.equals(body.get("isEnabled"));

        EmployeeModulePermission perm = permissionRepository
                .findByEmployeeIdAndFarmIdAndModuleName(id, farmId, module)
                .orElse(EmployeeModulePermission.builder()
                        .employeeId(id).farmId(farmId).moduleName(module).build());

        perm.setEnabled(enabled);
        permissionRepository.save(perm);

        return ResponseEntity.ok(Map.of("moduleName", module, "isEnabled", enabled));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void initDefaultPermissions(UUID employeeId, UUID farmId) {
        List<EmployeeModulePermission> defaults = AVAILABLE_MODULES.stream()
                .map(m -> EmployeeModulePermission.builder()
                        .employeeId(employeeId).farmId(farmId).moduleName(m).isEnabled(true).build())
                .collect(Collectors.toList());
        permissionRepository.saveAll(defaults);
    }
}
