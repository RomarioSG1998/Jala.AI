package com.aquasertao.api.modules.tenant.services;

import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.tenant.dtos.FarmTenantRequestDTO;
import com.aquasertao.api.modules.tenant.dtos.FarmTenantResponseDTO;
import com.aquasertao.api.modules.tenant.models.FarmTenant;
import com.aquasertao.api.modules.tenant.repositories.FarmTenantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.aquasertao.api.modules.general.services.NotificationService;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FarmTenantService {

    private final FarmTenantRepository farmTenantRepository;
    private final GlobalUserRepository globalUserRepository;
    private final NotificationService notificationService;

    public FarmTenantResponseDTO createFarmTenant(FarmTenantRequestDTO requestDTO) {
        FarmTenant farmTenant = FarmTenant.builder()
                .name(requestDTO.getName())
                .cnpj(requestDTO.getCnpj())
                .ownerId(requestDTO.getOwnerId())
                .build();

        FarmTenant savedFarmTenant = farmTenantRepository.save(farmTenant);

        // Disparar notificação real para Administradores do SaaS
        try {
            List<GlobalUser> saasAdmins = globalUserRepository.findByAccountType("SAAS_ADMIN");
            for (GlobalUser admin : saasAdmins) {
                notificationService.createNotification(
                        admin.getId(),
                        "Novo Cliente Cadastrado",
                        "TENANT_REGISTERED",
                        "A fazenda '" + savedFarmTenant.getName() + "' foi registrada com sucesso."
                );
            }
        } catch (Exception ignored) {}

        return mapToDTO(savedFarmTenant);
    }

    public Page<FarmTenantResponseDTO> getFarmsByOwnerId(UUID ownerId, Pageable pageable) {
        Page<FarmTenant> farmPage = farmTenantRepository.findByOwnerId(ownerId, pageable);
        return farmPage.map(this::mapToDTO);
    }

    public Page<FarmTenantResponseDTO> getAllFarms(Pageable pageable) {
        Page<FarmTenant> farmPage = farmTenantRepository.findAll(pageable);
        return farmPage.map(this::mapToDTO);
    }

    private FarmTenantResponseDTO mapToDTO(FarmTenant farmTenant) {
        GlobalUser owner = farmTenant.getOwnerId() != null
                ? globalUserRepository.findById(farmTenant.getOwnerId()).orElse(null)
                : null;

        UUID effectiveOwnerId = farmTenant.getOwnerId();
        if (effectiveOwnerId == null && owner == null) {
            // Fallback: use first user or john user ID if ownerId was missing in legacy records
            effectiveOwnerId = UUID.fromString("44444444-4444-4444-4444-444444444444");
        }

        return FarmTenantResponseDTO.builder()
                .id(farmTenant.getId())
                .name(farmTenant.getName())
                .cnpj(farmTenant.getCnpj())
                .ownerId(effectiveOwnerId)
                .ownerName(owner != null ? owner.getName() : "Produtor")
                .ownerEmail(owner != null ? owner.getEmail() : "N/A")
                .userActive(owner != null ? Boolean.TRUE.equals(owner.getActive()) : true)
                .createdAt(farmTenant.getCreatedAt())
                .build();
    }
}
