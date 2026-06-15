package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.MortalityRecordRequestDTO;
import com.aquasertao.api.modules.operational.dtos.MortalityRecordResponseDTO;
import com.aquasertao.api.modules.operational.models.MortalityRecord;
import com.aquasertao.api.modules.operational.models.Tank;
import com.aquasertao.api.modules.operational.repositories.MortalityRecordRepository;
import com.aquasertao.api.modules.operational.repositories.TankRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MortalityRecordService {

    private final MortalityRecordRepository mortalityRecordRepository;
    private final TankRepository tankRepository;

    @Transactional
    public MortalityRecordResponseDTO createRecord(MortalityRecordRequestDTO requestDTO) {
        Tank tank = tankRepository.findByIdAndFarmId(requestDTO.getTankId(), requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied."));

        // Update tank's mortalityCount
        int currentCount = tank.getMortalityCount() != null ? tank.getMortalityCount() : 0;
        tank.setMortalityCount(currentCount + requestDTO.getQuantity());
        tankRepository.save(tank);

        LocalDateTime recordDate = LocalDateTime.now();
        if (requestDTO.getRecordDate() != null && !requestDTO.getRecordDate().isEmpty()) {
            try {
                recordDate = LocalDateTime.parse(requestDTO.getRecordDate());
            } catch (Exception e) {
                // Keep now()
            }
        }

        MortalityRecord mortalityRecord = MortalityRecord.builder()
                .farmId(requestDTO.getFarmId())
                .tankId(requestDTO.getTankId())
                .quantity(requestDTO.getQuantity())
                .cause(requestDTO.getCause())
                .recordDate(recordDate)
                .build();

        MortalityRecord savedRecord = mortalityRecordRepository.save(mortalityRecord);
        return mapToDTO(savedRecord);
    }

    @Transactional
    public MortalityRecordResponseDTO updateRecord(UUID id, MortalityRecordRequestDTO requestDTO) {
        MortalityRecord existingRecord = mortalityRecordRepository.findByIdAndFarmId(id, requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Mortality record not found or access denied."));

        Tank tank = tankRepository.findByIdAndFarmId(requestDTO.getTankId(), requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied."));

        // Adjust tank's mortalityCount based on the difference
        int diff = requestDTO.getQuantity() - existingRecord.getQuantity();
        int currentCount = tank.getMortalityCount() != null ? tank.getMortalityCount() : 0;
        tank.setMortalityCount(currentCount + diff);
        tankRepository.save(tank);

        existingRecord.setQuantity(requestDTO.getQuantity());
        existingRecord.setCause(requestDTO.getCause());
        if (requestDTO.getRecordDate() != null && !requestDTO.getRecordDate().isEmpty()) {
            try {
                existingRecord.setRecordDate(LocalDateTime.parse(requestDTO.getRecordDate()));
            } catch (Exception e) {
                // Keep existing
            }
        }

        MortalityRecord saved = mortalityRecordRepository.save(existingRecord);
        return mapToDTO(saved);
    }

    @Transactional
    public void deleteRecord(UUID id, UUID farmId) {
        MortalityRecord record = mortalityRecordRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Mortality record not found or access denied."));

        Tank tank = tankRepository.findByIdAndFarmId(record.getTankId(), farmId)
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied."));

        int currentCount = tank.getMortalityCount() != null ? tank.getMortalityCount() : 0;
        tank.setMortalityCount(Math.max(0, currentCount - record.getQuantity()));
        tankRepository.save(tank);

        mortalityRecordRepository.delete(record);
    }

    public Page<MortalityRecordResponseDTO> getRecordsByFarmId(UUID farmId, Pageable pageable) {
        return mortalityRecordRepository.findByFarmId(farmId, pageable)
                .map(this::mapToDTO);
    }

    public List<MortalityRecordResponseDTO> getRecordsByTank(UUID tankId, UUID farmId) {
        return mortalityRecordRepository.findByTankIdAndFarmIdOrderByRecordDateDesc(tankId, farmId)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public MortalityRecordResponseDTO getById(UUID id, UUID farmId) {
        MortalityRecord record = mortalityRecordRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Mortality record not found or access denied."));
        return mapToDTO(record);
    }

    private MortalityRecordResponseDTO mapToDTO(MortalityRecord record) {
        return MortalityRecordResponseDTO.builder()
                .id(record.getId())
                .farmId(record.getFarmId())
                .tankId(record.getTankId())
                .quantity(record.getQuantity())
                .cause(record.getCause())
                .recordDate(record.getRecordDate())
                .build();
    }
}
