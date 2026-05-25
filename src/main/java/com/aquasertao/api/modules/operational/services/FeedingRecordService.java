package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.FeedingRecordRequestDTO;
import com.aquasertao.api.modules.operational.dtos.FeedingRecordResponseDTO;
import com.aquasertao.api.modules.operational.models.FeedingRecord;
import com.aquasertao.api.modules.operational.models.Inventory;
import com.aquasertao.api.modules.operational.repositories.FeedingRecordRepository;
import com.aquasertao.api.modules.operational.repositories.InventoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FeedingRecordService {

    private final FeedingRecordRepository feedingRecordRepository;
    private final InventoryRepository inventoryRepository;

    @Transactional
    public FeedingRecordResponseDTO createFeedingRecord(FeedingRecordRequestDTO requestDTO) {
        
        // 1. Fetch the Inventory Feed item
        Inventory inventory = inventoryRepository.findById(requestDTO.getFeedId())
                .orElseThrow(() -> new IllegalArgumentException("Feed Inventory Item not found."));
                
        // 2. Security Check: Ensure the feed belongs to the same farm
        if (!inventory.getFarmId().equals(requestDTO.getFarmId())) {
            throw new SecurityException("Feed does not belong to this farm.");
        }
        
        // 3. Logic Check: Ensure enough feed is available
        if (inventory.getQuantity().compareTo(requestDTO.getQuantity()) < 0) {
            throw new IllegalArgumentException("Insufficient feed in inventory.");
        }
        
        // 4. Deduct the feed and save inventory
        inventory.setQuantity(inventory.getQuantity().subtract(requestDTO.getQuantity()));
        inventoryRepository.save(inventory);

        // 5. Create and save the Feeding Record
        FeedingRecord feedingRecord = FeedingRecord.builder()
                .farmId(requestDTO.getFarmId())
                .tankId(requestDTO.getTankId())
                .userId(requestDTO.getUserId())
                .feedId(requestDTO.getFeedId())
                .quantity(requestDTO.getQuantity())
                .feedingTime(LocalDateTime.now())
                .build();

        FeedingRecord savedRecord = feedingRecordRepository.save(feedingRecord);
        return mapToDTO(savedRecord);
    }

    public Page<FeedingRecordResponseDTO> getFeedingRecordsByFarmId(UUID farmId, Pageable pageable) {
        Page<FeedingRecord> recordsPage = feedingRecordRepository.findByFarmId(farmId, pageable);
        return recordsPage.map(this::mapToDTO);
    }

    public FeedingRecordResponseDTO getById(UUID id, UUID farmId) {
        FeedingRecord record = feedingRecordRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Feeding Record not found or access denied"));
        return mapToDTO(record);
    }

    @Transactional
    public FeedingRecordResponseDTO updateFeedingRecord(UUID id, FeedingRecordRequestDTO requestDTO) {
        FeedingRecord existingRecord = feedingRecordRepository.findByIdAndFarmId(id, requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Feeding Record not found or access denied"));

        // If feedId or quantity changed, we need to adjust inventory
        if (!existingRecord.getFeedId().equals(requestDTO.getFeedId()) || existingRecord.getQuantity().compareTo(requestDTO.getQuantity()) != 0) {
            
            // 1. Restore old quantity to old inventory
            Inventory oldInventory = inventoryRepository.findById(existingRecord.getFeedId()).orElse(null);
            if (oldInventory != null) {
                oldInventory.setQuantity(oldInventory.getQuantity().add(existingRecord.getQuantity()));
                inventoryRepository.save(oldInventory);
            }

            // 2. Deduct new quantity from new inventory
            Inventory newInventory = inventoryRepository.findById(requestDTO.getFeedId())
                    .orElseThrow(() -> new IllegalArgumentException("New Feed Inventory Item not found."));
            
            if (newInventory.getQuantity().compareTo(requestDTO.getQuantity()) < 0) {
                throw new IllegalArgumentException("Insufficient feed in inventory.");
            }
            
            newInventory.setQuantity(newInventory.getQuantity().subtract(requestDTO.getQuantity()));
            inventoryRepository.save(newInventory);
        }

        existingRecord.setTankId(requestDTO.getTankId());
        existingRecord.setUserId(requestDTO.getUserId());
        existingRecord.setFeedId(requestDTO.getFeedId());
        existingRecord.setQuantity(requestDTO.getQuantity());

        FeedingRecord updatedRecord = feedingRecordRepository.save(existingRecord);
        return mapToDTO(updatedRecord);
    }

    @Transactional
    public void deleteFeedingRecord(UUID id, UUID farmId) {
        FeedingRecord record = feedingRecordRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Feeding Record not found or access denied"));
                
        // Restore inventory
        inventoryRepository.findById(record.getFeedId()).ifPresent(inventory -> {
            inventory.setQuantity(inventory.getQuantity().add(record.getQuantity()));
            inventoryRepository.save(inventory);
        });

        feedingRecordRepository.deleteById(id);
    }

    private FeedingRecordResponseDTO mapToDTO(FeedingRecord record) {
        return FeedingRecordResponseDTO.builder()
                .id(record.getId())
                .farmId(record.getFarmId())
                .tankId(record.getTankId())
                .userId(record.getUserId())
                .feedId(record.getFeedId())
                .quantity(record.getQuantity())
                .feedingTime(record.getFeedingTime())
                .build();
    }
}
