package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.InventoryRequestDTO;
import com.aquasertao.api.modules.operational.dtos.InventoryResponseDTO;
import com.aquasertao.api.modules.operational.models.Inventory;
import com.aquasertao.api.modules.operational.repositories.InventoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryRepository inventoryRepository;

    public InventoryResponseDTO createInventoryItem(InventoryRequestDTO requestDTO) {
        Inventory inventory = Inventory.builder()
                .farmId(requestDTO.getFarmId())
                .itemName(requestDTO.getItemName())
                .quantity(requestDTO.getQuantity())
                .unit(requestDTO.getUnit())
                .type(requestDTO.getType())
                .build();

        Inventory savedInventory = inventoryRepository.save(inventory);
        return mapToDTO(savedInventory);
    }

    public Page<InventoryResponseDTO> getInventoryByFarmId(UUID farmId, Pageable pageable) {
        // Enforcing Tenant Isolation at the database query level
        Page<Inventory> inventoryPage = inventoryRepository.findByFarmId(farmId, pageable);
        return inventoryPage.map(this::mapToDTO);
    }

    private InventoryResponseDTO mapToDTO(Inventory inventory) {
        return InventoryResponseDTO.builder()
                .id(inventory.getId())
                .farmId(inventory.getFarmId())
                .itemName(inventory.getItemName())
                .quantity(inventory.getQuantity())
                .unit(inventory.getUnit())
                .type(inventory.getType())
                .build();
    }
}
