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

    public HarvestResponseDTO getById(UUID id, UUID farmId) {
        Harvest harvest = harvestRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Harvest not found or access denied"));
        return mapToDTO(harvest);
    }

    public HarvestResponseDTO updateHarvest(UUID id, HarvestRequestDTO requestDTO) {
        Harvest existingHarvest = harvestRepository.findByIdAndFarmId(id, requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Harvest not found or access denied"));

        existingHarvest.setTankId(requestDTO.getTankId());
        existingHarvest.setDate(requestDTO.getDate());
        existingHarvest.setQuantityKg(requestDTO.getQuantityKg());
        existingHarvest.setDestination(requestDTO.getDestination());

        Harvest updatedHarvest = harvestRepository.save(existingHarvest);
        return mapToDTO(updatedHarvest);
    }

    public void deleteHarvest(UUID id, UUID farmId) {
        if (!harvestRepository.existsByIdAndFarmId(id, farmId)) {
            throw new IllegalArgumentException("Harvest not found or access denied");
        }
        harvestRepository.deleteById(id);
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
