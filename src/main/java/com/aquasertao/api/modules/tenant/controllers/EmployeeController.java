package com.aquasertao.api.modules.tenant.controllers;

import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.tenant.dtos.EmployeeRequestDTO;
import com.aquasertao.api.modules.tenant.dtos.EmployeeResponseDTO;
import com.aquasertao.api.modules.tenant.models.UserFarmLink;
import com.aquasertao.api.modules.tenant.repositories.UserFarmLinkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final GlobalUserRepository globalUserRepository;
    private final UserFarmLinkRepository userFarmLinkRepository;
    private final PasswordEncoder passwordEncoder;

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

    @PostMapping
    @Transactional
    public ResponseEntity<?> createEmployee(@RequestBody EmployeeRequestDTO requestDTO) {
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

        EmployeeResponseDTO response = EmployeeResponseDTO.builder()
                .id(savedEmployee.getId())
                .name(savedEmployee.getName())
                .email(savedEmployee.getEmail())
                .accountType(savedEmployee.getAccountType())
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<?> updateEmployee(@PathVariable UUID id, @RequestBody EmployeeRequestDTO requestDTO) {
        GlobalUser employee = globalUserRepository.findById(id)
                .orElse(null);
        if (employee == null) {
            return ResponseEntity.notFound().build();
        }

        // If email is changing, check if the new email is already registered by another user
        if (!employee.getEmail().equalsIgnoreCase(requestDTO.getEmail()) &&
                globalUserRepository.findByEmail(requestDTO.getEmail()).isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Email already registered.");
        }

        employee.setName(requestDTO.getName());
        employee.setEmail(requestDTO.getEmail());
        if (requestDTO.getPassword() != null && !requestDTO.getPassword().trim().isEmpty()) {
            employee.setPassword(passwordEncoder.encode(requestDTO.getPassword()));
        }

        GlobalUser savedEmployee = globalUserRepository.save(employee);

        EmployeeResponseDTO response = EmployeeResponseDTO.builder()
                .id(savedEmployee.getId())
                .name(savedEmployee.getName())
                .email(savedEmployee.getEmail())
                .accountType(savedEmployee.getAccountType())
                .build();

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}/farm/{farmId}")
    @Transactional
    public ResponseEntity<Void> deleteEmployee(@PathVariable UUID id, @PathVariable UUID farmId) {
        // Ensure user is linked as employee before deleting
        UserFarmLink.UserFarmLinkId linkId = new UserFarmLink.UserFarmLinkId(id, farmId);
        if (!userFarmLinkRepository.existsById(linkId)) {
            return ResponseEntity.notFound().build();
        }

        // Delete user (cascades to delete the farm link)
        globalUserRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
