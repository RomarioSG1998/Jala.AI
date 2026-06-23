package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.operational.dtos.WaterQualityRequestDTO;
import com.aquasertao.api.modules.operational.dtos.WaterQualityResponseDTO;
import com.aquasertao.api.modules.operational.models.WaterQuality;
import com.aquasertao.api.modules.operational.repositories.WaterQualityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WaterQualityService {

    private final WaterQualityRepository waterQualityRepository;

    public WaterQualityResponseDTO logWaterQuality(WaterQualityRequestDTO requestDTO) {
        WaterQuality waterQuality = WaterQuality.builder()
                .farmId(requestDTO.getFarmId())
                .tankId(requestDTO.getTankId())
                .ph(requestDTO.getPh())
                .temperature(requestDTO.getTemperature())
                .dissolvedOxygen(requestDTO.getDissolvedOxygen())
                .ammonia(requestDTO.getAmmonia())
                .nitrite(requestDTO.getNitrite())
                .alkalinity(requestDTO.getAlkalinity())
                .hardness(requestDTO.getHardness())
                .solids(requestDTO.getSolids())
                .measurementTime(LocalDateTime.now())
                .build();

        WaterQuality savedWaterQuality = waterQualityRepository.save(waterQuality);
        return mapToDTO(savedWaterQuality);
    }

    public Page<WaterQualityResponseDTO> getWaterQualityByFarmId(UUID farmId, Pageable pageable) {
        Page<WaterQuality> waterQualityPage = waterQualityRepository.findByFarmId(farmId, pageable);
        return waterQualityPage.map(this::mapToDTO);
    }

    public WaterQualityResponseDTO getById(UUID id, UUID farmId) {
        WaterQuality waterQuality = waterQualityRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Water quality record not found or access denied"));
        return mapToDTO(waterQuality);
    }

    public WaterQualityResponseDTO getLatestByTankId(UUID tankId, UUID farmId) {
        WaterQuality waterQuality = waterQualityRepository.findTopByTankIdAndFarmIdOrderByMeasurementTimeDesc(tankId, farmId)
                .orElseThrow(() -> new IllegalArgumentException("No water quality records found for this tank"));
        return mapToDTO(waterQuality);
    }

    public WaterQualityResponseDTO updateWaterQuality(UUID id, WaterQualityRequestDTO requestDTO) {
        WaterQuality existingRecord = waterQualityRepository.findByIdAndFarmId(id, requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Water quality record not found or access denied"));

        existingRecord.setTankId(requestDTO.getTankId());
        existingRecord.setPh(requestDTO.getPh());
        existingRecord.setTemperature(requestDTO.getTemperature());
        existingRecord.setDissolvedOxygen(requestDTO.getDissolvedOxygen());
        existingRecord.setAmmonia(requestDTO.getAmmonia());
        existingRecord.setNitrite(requestDTO.getNitrite());
        existingRecord.setAlkalinity(requestDTO.getAlkalinity());
        existingRecord.setHardness(requestDTO.getHardness());
        existingRecord.setSolids(requestDTO.getSolids());

        WaterQuality updatedRecord = waterQualityRepository.save(existingRecord);
        return mapToDTO(updatedRecord);
    }

    public void deleteWaterQuality(UUID id, UUID farmId) {
        if (!waterQualityRepository.existsByIdAndFarmId(id, farmId)) {
            throw new IllegalArgumentException("Water quality record not found or access denied");
        }
        waterQualityRepository.deleteById(id);
    }

    private WaterQualityResponseDTO mapToDTO(WaterQuality waterQuality) {
        return WaterQualityResponseDTO.builder()
                .id(waterQuality.getId())
                .farmId(waterQuality.getFarmId())
                .tankId(waterQuality.getTankId())
                .ph(waterQuality.getPh())
                .temperature(waterQuality.getTemperature())
                .dissolvedOxygen(waterQuality.getDissolvedOxygen())
                .ammonia(waterQuality.getAmmonia())
                .nitrite(waterQuality.getNitrite())
                .alkalinity(waterQuality.getAlkalinity())
                .hardness(waterQuality.getHardness())
                .solids(waterQuality.getSolids())
                .measurementTime(waterQuality.getMeasurementTime())
                .build();
    }
}
