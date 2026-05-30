package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.FeedingRecordRequestDTO;
import com.aquasertao.api.modules.operational.dtos.FeedingRecordResponseDTO;
import com.aquasertao.api.modules.operational.models.FeedingRecord;
import com.aquasertao.api.modules.operational.models.Inventory;
import com.aquasertao.api.modules.operational.repositories.FeedingRecordRepository;
import com.aquasertao.api.modules.operational.repositories.InventoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FeedingRecordServiceTest {

    @Mock
    private FeedingRecordRepository feedingRecordRepository;

    @Mock
    private InventoryRepository inventoryRepository;

    @InjectMocks
    private FeedingRecordService feedingRecordService;

    private UUID farmId;
    private UUID feedId;
    private FeedingRecordRequestDTO requestDTO;
    private Inventory inventory;

    @BeforeEach
    void setUp() {
        farmId = UUID.randomUUID();
        feedId = UUID.randomUUID();

        requestDTO = FeedingRecordRequestDTO.builder()
                .farmId(farmId)
                .tankId(UUID.randomUUID())
                .userId(UUID.randomUUID())
                .feedId(feedId)
                .quantity(new BigDecimal("10.50"))
                .build();

        inventory = Inventory.builder()
                .id(feedId)
                .farmId(farmId)
                .itemName("Premium Fish Feed")
                .quantity(new BigDecimal("50.00")) // 50kg in stock
                .unit("kg")
                .type("FEED")
                .build();
    }

    @Test
    void createFeedingRecord_ShouldDeductInventoryAndSaveRecord() {
        // Arrange
        when(inventoryRepository.findById(feedId)).thenReturn(Optional.of(inventory));
        when(feedingRecordRepository.save(any(FeedingRecord.class))).thenAnswer(i -> {
            FeedingRecord record = i.getArgument(0);
            record.setId(UUID.randomUUID());
            return record;
        });

        // Act
        FeedingRecordResponseDTO response = feedingRecordService.createFeedingRecord(requestDTO);

        // Assert
        assertNotNull(response);
        assertEquals(new BigDecimal("10.50"), response.getQuantity());
        
        // Ensure inventory was deducted (50 - 10.50 = 39.50)
        assertEquals(new BigDecimal("39.50"), inventory.getQuantity());
        
        verify(inventoryRepository).save(inventory);
        verify(feedingRecordRepository).save(any(FeedingRecord.class));
    }

    @Test
    void createFeedingRecord_ShouldThrowException_WhenInsufficientInventory() {
        // Arrange
        // Only 5kg in stock, but request is for 10.50kg
        inventory.setQuantity(new BigDecimal("5.00")); 
        when(inventoryRepository.findById(feedId)).thenReturn(Optional.of(inventory));

        // Act & Assert
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, 
            () -> feedingRecordService.createFeedingRecord(requestDTO));
            
        assertEquals("Insufficient feed in inventory.", exception.getMessage());
        
        verify(inventoryRepository, never()).save(any(Inventory.class));
        verify(feedingRecordRepository, never()).save(any(FeedingRecord.class));
    }

    @Test
    void createFeedingRecord_ShouldThrowException_WhenSecurityCheckFails() {
        // Arrange
        // Inventory belongs to a DIFFERENT farm
        inventory.setFarmId(UUID.randomUUID()); 
        when(inventoryRepository.findById(feedId)).thenReturn(Optional.of(inventory));

        // Act & Assert
        SecurityException exception = assertThrows(SecurityException.class, 
            () -> feedingRecordService.createFeedingRecord(requestDTO));
            
        assertEquals("Feed does not belong to this farm.", exception.getMessage());
    }
}
