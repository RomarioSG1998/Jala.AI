package com.aquasertao.api.modules.marketplace.services;

import com.aquasertao.api.modules.marketplace.dtos.SupplierProfileDTO;
import com.aquasertao.api.modules.marketplace.models.SupplierProfile;
import com.aquasertao.api.modules.marketplace.repositories.SupplierProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SupplierProfileService {

    private final SupplierProfileRepository profileRepository;

    @Transactional
    public SupplierProfileDTO registerOrUpdateProfile(SupplierProfileDTO dto) {
        if (dto.getFarmId() == null) {
            throw new IllegalArgumentException("farmId é obrigatório para registrar o fornecedor.");
        }

        SupplierProfile profile = profileRepository.findByFarmId(dto.getFarmId())
                .orElse(SupplierProfile.builder().farmId(dto.getFarmId()).build());

        profile.setCompanyName(dto.getCompanyName() != null ? dto.getCompanyName() : "Fornecedor Local");
        profile.setDocumentNumber(dto.getDocumentNumber());
        profile.setStateRegistration(dto.getStateRegistration());
        profile.setPhone(dto.getPhone());
        profile.setEmail(dto.getEmail());
        profile.setAddress(dto.getAddress());
        profile.setCity(dto.getCity());
        profile.setState(dto.getState());
        profile.setPixKey(dto.getPixKey());
        profile.setPixKeyType(dto.getPixKeyType() != null ? dto.getPixKeyType() : "CPF_CNPJ");
        profile.setVerified(true);

        SupplierProfile saved = profileRepository.save(profile);
        return toDTO(saved);
    }

    public SupplierProfileDTO getProfileByFarmId(UUID farmId) {
        return profileRepository.findByFarmId(farmId)
                .map(this::toDTO)
                .orElse(null);
    }

    private SupplierProfileDTO toDTO(SupplierProfile p) {
        return SupplierProfileDTO.builder()
                .id(p.getId())
                .farmId(p.getFarmId())
                .companyName(p.getCompanyName())
                .documentNumber(p.getDocumentNumber())
                .stateRegistration(p.getStateRegistration())
                .phone(p.getPhone())
                .email(p.getEmail())
                .address(p.getAddress())
                .city(p.getCity())
                .state(p.getState())
                .pixKey(p.getPixKey())
                .pixKeyType(p.getPixKeyType())
                .verified(p.getVerified())
                .createdAt(p.getCreatedAt())
                .build();
    }
}
