package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.TankRequestDTO;
import com.aquasertao.api.modules.operational.dtos.TankResponseDTO;
import com.aquasertao.api.modules.operational.models.Tank;
import com.aquasertao.api.modules.operational.repositories.TankRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TankService {

    private final TankRepository tankRepository;

    public TankResponseDTO createTank(TankRequestDTO requestDTO) {
        Tank tank = Tank.builder()
                .farmId(requestDTO.getFarmId())
                .name(requestDTO.getName())
                .fishSpecies(requestDTO.getFishSpecies())
                .fishCapacity(requestDTO.getFishCapacity())
                .build();

        Tank savedTank = tankRepository.save(tank);
        return mapToDTO(savedTank);
    }

    public Page<TankResponseDTO> getTanksByFarmId(UUID farmId, Pageable pageable) {
        // Enforcing Tenant Isolation at the database query level
        Page<Tank> tankPage = tankRepository.findByFarmId(farmId, pageable);
        return tankPage.map(this::mapToDTO);
    }

    private TankResponseDTO mapToDTO(Tank tank) {
        return TankResponseDTO.builder()
                .id(tank.getId())
                .farmId(tank.getFarmId())
                .name(tank.getName())
                .fishSpecies(tank.getFishSpecies())
                .fishCapacity(tank.getFishCapacity())
                .build();
    }
}
