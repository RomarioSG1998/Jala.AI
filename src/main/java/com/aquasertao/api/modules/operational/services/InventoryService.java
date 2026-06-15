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
                .power(requestDTO.getPower())
                .unitCost(requestDTO.getUnitCost())
                .build();

        Inventory savedInventory = inventoryRepository.save(inventory);
        return mapToDTO(savedInventory);
    }

    public Page<InventoryResponseDTO> getInventoryByFarmId(UUID farmId, Pageable pageable) {
        // Enforcing Tenant Isolation at the database query level
        Page<Inventory> inventoryPage = inventoryRepository.findByFarmId(farmId, pageable);
        return inventoryPage.map(this::mapToDTO);
    }

    public InventoryResponseDTO getById(UUID id, UUID farmId) {
        Inventory inventory = inventoryRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Inventory item not found or access denied"));
        return mapToDTO(inventory);
    }

    public InventoryResponseDTO updateInventoryItem(UUID id, InventoryRequestDTO requestDTO) {
        Inventory existingInventory = inventoryRepository.findByIdAndFarmId(id, requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Inventory item not found or access denied"));

        existingInventory.setItemName(requestDTO.getItemName());
        existingInventory.setQuantity(requestDTO.getQuantity());
        existingInventory.setUnit(requestDTO.getUnit());
        existingInventory.setType(requestDTO.getType());
        existingInventory.setPower(requestDTO.getPower());
        existingInventory.setUnitCost(requestDTO.getUnitCost());

        Inventory updatedInventory = inventoryRepository.save(existingInventory);
        return mapToDTO(updatedInventory);
    }

    public void deleteInventoryItem(UUID id, UUID farmId) {
        if (!inventoryRepository.existsByIdAndFarmId(id, farmId)) {
            throw new IllegalArgumentException("Inventory item not found or access denied");
        }
        inventoryRepository.deleteById(id);
    }

    private InventoryResponseDTO mapToDTO(Inventory inventory) {
        return InventoryResponseDTO.builder()
                .id(inventory.getId())
                .farmId(inventory.getFarmId())
                .itemName(inventory.getItemName())
                .quantity(inventory.getQuantity())
                .unit(inventory.getUnit())
                .type(inventory.getType())
                .power(inventory.getPower())
                .unitCost(inventory.getUnitCost())
                .build();
    }
}
