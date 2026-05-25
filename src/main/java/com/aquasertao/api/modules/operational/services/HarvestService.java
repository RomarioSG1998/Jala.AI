package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.HarvestRequestDTO;
import com.aquasertao.api.modules.operational.dtos.HarvestResponseDTO;
import com.aquasertao.api.modules.operational.models.Harvest;
import com.aquasertao.api.modules.operational.repositories.HarvestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HarvestService {

    private final HarvestRepository harvestRepository;

    public HarvestResponseDTO logHarvest(HarvestRequestDTO requestDTO) {
        Harvest harvest = Harvest.builder()
                .farmId(requestDTO.getFarmId())
                .tankId(requestDTO.getTankId())
                .date(requestDTO.getDate())
                .quantityKg(requestDTO.getQuantityKg())
                .destination(requestDTO.getDestination())
                .build();

        Harvest savedHarvest = harvestRepository.save(harvest);
        return mapToDTO(savedHarvest);
    }

    public Page<HarvestResponseDTO> getHarvestsByFarmId(UUID farmId, Pageable pageable) {
        // Enforcing Tenant Isolation at the database query level
        Page<Harvest> harvestPage = harvestRepository.findByFarmId(farmId, pageable);
        return harvestPage.map(this::mapToDTO);
    }

    private HarvestResponseDTO mapToDTO(Harvest harvest) {
        return HarvestResponseDTO.builder()
                .id(harvest.getId())
                .farmId(harvest.getFarmId())
                .tankId(harvest.getTankId())
                .date(harvest.getDate())
                .quantityKg(harvest.getQuantityKg())
                .destination(harvest.getDestination())
                .build();
    }
}
