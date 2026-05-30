package com.aquasertao.api.modules.tenant.services;

import com.aquasertao.api.modules.tenant.dtos.FarmTenantRequestDTO;
import com.aquasertao.api.modules.tenant.dtos.FarmTenantResponseDTO;
import com.aquasertao.api.modules.tenant.models.FarmTenant;
import com.aquasertao.api.modules.tenant.repositories.FarmTenantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FarmTenantService {

    private final FarmTenantRepository farmTenantRepository;

    public FarmTenantResponseDTO createFarmTenant(FarmTenantRequestDTO requestDTO) {
        FarmTenant farmTenant = FarmTenant.builder()
                .name(requestDTO.getName())
                .cnpj(requestDTO.getCnpj())
                .ownerId(requestDTO.getOwnerId())
                .build();

        FarmTenant savedFarmTenant = farmTenantRepository.save(farmTenant);
        return mapToDTO(savedFarmTenant);
    }

    public Page<FarmTenantResponseDTO> getFarmsByOwnerId(UUID ownerId, Pageable pageable) {
        Page<FarmTenant> farmPage = farmTenantRepository.findByOwnerId(ownerId, pageable);
        return farmPage.map(this::mapToDTO);
    }

    private FarmTenantResponseDTO mapToDTO(FarmTenant farmTenant) {
        return FarmTenantResponseDTO.builder()
                .id(farmTenant.getId())
                .name(farmTenant.getName())
                .cnpj(farmTenant.getCnpj())
                .ownerId(farmTenant.getOwnerId())
                .createdAt(farmTenant.getCreatedAt())
                .build();
    }
}
