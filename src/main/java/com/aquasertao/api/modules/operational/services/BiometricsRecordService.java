package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.BiometricsRecordRequestDTO;
import com.aquasertao.api.modules.operational.dtos.BiometricsRecordResponseDTO;
import com.aquasertao.api.modules.operational.models.BiometricsRecord;
import com.aquasertao.api.modules.operational.models.Tank;
import com.aquasertao.api.modules.operational.repositories.BiometricsRecordRepository;
import com.aquasertao.api.modules.operational.repositories.TankRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BiometricsRecordService {

    private final BiometricsRecordRepository biometricsRecordRepository;
    private final TankRepository tankRepository;

    @Transactional
    public BiometricsRecordResponseDTO createBiometricsRecord(BiometricsRecordRequestDTO requestDTO) {
        Tank tank = tankRepository.findByIdAndFarmId(requestDTO.getTankId(), requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied."));

        // Update tank's average weight to the new recorded value
        tank.setAverageWeightG(requestDTO.getWeightG());
        tankRepository.save(tank);

        BiometricsRecord biometricsRecord = BiometricsRecord.builder()
                .farmId(requestDTO.getFarmId())
                .tankId(requestDTO.getTankId())
                .weightG(requestDTO.getWeightG())
                .recordDate(requestDTO.getRecordDate() != null ? requestDTO.getRecordDate() : LocalDate.now())
                .build();

        BiometricsRecord savedRecord = biometricsRecordRepository.save(biometricsRecord);
        return mapToDTO(savedRecord);
    }

    public List<BiometricsRecordResponseDTO> getBiometricsByTank(UUID tankId, UUID farmId) {
        return biometricsRecordRepository.findByTankIdAndFarmIdOrderByRecordDateDesc(tankId, farmId)
                .stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteBiometricsRecord(UUID id, UUID farmId) {
        BiometricsRecord record = biometricsRecordRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Biometrics record not found or access denied."));
        biometricsRecordRepository.delete(record);
    }

    private BiometricsRecordResponseDTO mapToDTO(BiometricsRecord record) {
        return BiometricsRecordResponseDTO.builder()
                .id(record.getId())
                .farmId(record.getFarmId())
                .tankId(record.getTankId())
                .weightG(record.getWeightG())
                .recordDate(record.getRecordDate())
                .build();
    }
}
