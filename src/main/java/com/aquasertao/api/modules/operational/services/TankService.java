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

    public TankResponseDTO getById(UUID id, UUID farmId) {
        Tank tank = tankRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied"));
        return mapToDTO(tank);
    }

    public TankResponseDTO updateTank(UUID id, TankRequestDTO requestDTO) {
        Tank existingTank = tankRepository.findByIdAndFarmId(id, requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied"));

        existingTank.setName(requestDTO.getName());
        existingTank.setFishSpecies(requestDTO.getFishSpecies());
        existingTank.setFishCapacity(requestDTO.getFishCapacity());

        Tank updatedTank = tankRepository.save(existingTank);
        return mapToDTO(updatedTank);
    }

    public void deleteTank(UUID id, UUID farmId) {
        if (!tankRepository.existsByIdAndFarmId(id, farmId)) {
            throw new IllegalArgumentException("Tank not found or access denied");
        }
        tankRepository.deleteById(id);
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
