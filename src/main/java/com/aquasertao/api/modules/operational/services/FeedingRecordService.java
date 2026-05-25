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
