package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.MaintenanceRequestDTO;
import com.aquasertao.api.modules.operational.dtos.MaintenanceResponseDTO;
import com.aquasertao.api.modules.operational.models.Maintenance;
import com.aquasertao.api.modules.operational.repositories.MaintenanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MaintenanceService {

    private final MaintenanceRepository maintenanceRepository;

    public MaintenanceResponseDTO logMaintenance(MaintenanceRequestDTO requestDTO) {
        Maintenance maintenance = Maintenance.builder()
                .farmId(requestDTO.getFarmId())
                .tankId(requestDTO.getTankId())
                .description(requestDTO.getDescription())
                .status(requestDTO.getStatus())
                .scheduledDate(requestDTO.getScheduledDate())
                .build();

        Maintenance savedMaintenance = maintenanceRepository.save(maintenance);
        return mapToDTO(savedMaintenance);
    }

    public Page<MaintenanceResponseDTO> getMaintenanceByFarmId(UUID farmId, Pageable pageable) {
        Page<Maintenance> maintenancePage = maintenanceRepository.findByFarmId(farmId, pageable);
        return maintenancePage.map(this::mapToDTO);
    }

    private MaintenanceResponseDTO mapToDTO(Maintenance maintenance) {
        return MaintenanceResponseDTO.builder()
                .id(maintenance.getId())
                .farmId(maintenance.getFarmId())
                .tankId(maintenance.getTankId())
                .description(maintenance.getDescription())
                .status(maintenance.getStatus())
                .scheduledDate(maintenance.getScheduledDate())
                .build();
    }
}
