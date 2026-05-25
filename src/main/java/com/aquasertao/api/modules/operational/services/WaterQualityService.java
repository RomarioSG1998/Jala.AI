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
                .measurementTime(LocalDateTime.now())
                .build();

        WaterQuality savedWaterQuality = waterQualityRepository.save(waterQuality);
        return mapToDTO(savedWaterQuality);
    }

    public Page<WaterQualityResponseDTO> getWaterQualityByFarmId(UUID farmId, Pageable pageable) {
        Page<WaterQuality> waterQualityPage = waterQualityRepository.findByFarmId(farmId, pageable);
        return waterQualityPage.map(this::mapToDTO);
    }

    private WaterQualityResponseDTO mapToDTO(WaterQuality waterQuality) {
        return WaterQualityResponseDTO.builder()
                .id(waterQuality.getId())
                .farmId(waterQuality.getFarmId())
                .tankId(waterQuality.getTankId())
                .ph(waterQuality.getPh())
                .temperature(waterQuality.getTemperature())
                .dissolvedOxygen(waterQuality.getDissolvedOxygen())
                .measurementTime(waterQuality.getMeasurementTime())
                .build();
    }
}
