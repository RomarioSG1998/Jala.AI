package com.aquasertao.api.modules.supplier.services;

import com.aquasertao.api.modules.supplier.dtos.SupplierRequestDTO;
import com.aquasertao.api.modules.supplier.dtos.SupplierResponseDTO;
import com.aquasertao.api.modules.supplier.models.NationalSupplier;
import com.aquasertao.api.modules.supplier.repositories.NationalSupplierRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class NationalSupplierService {

    private final NationalSupplierRepository nationalSupplierRepository;
    private final RabbitTemplate rabbitTemplate;

    public SupplierResponseDTO createSupplier(SupplierRequestDTO requestDTO) {
        NationalSupplier supplier = NationalSupplier.builder()
                .companyName(requestDTO.getCompanyName())
                .cnpj(requestDTO.getCnpj())
                .supplyType(requestDTO.getSupplyType())
                .isApproved(false) // Requires SaaS Admin approval
                .build();

        NationalSupplier saved = nationalSupplierRepository.save(supplier);
        return mapToDTO(saved);
    }

    public List<SupplierResponseDTO> getAllSuppliers() {
        return nationalSupplierRepository.findAll().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public SupplierResponseDTO approveSupplier(UUID id) {
        NationalSupplier supplier = nationalSupplierRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Fornecedor não encontrado"));
        supplier.setIsApproved(true);
        NationalSupplier saved = nationalSupplierRepository.save(supplier);

        try {
            if (rabbitTemplate != null) {
                rabbitTemplate.convertAndSend("supplier.exchange", "supplier.approved", saved.getId().toString());
            }
        } catch (Exception e) {
            log.warn("Erro ao publicar evento de aprovação do fornecedor no RabbitMQ: {}", e.getMessage());
        }

        return mapToDTO(saved);
    }

    public void deleteSupplier(UUID id) {
        if (!nationalSupplierRepository.existsById(id)) {
            throw new IllegalArgumentException("Fornecedor não encontrado");
        }
        nationalSupplierRepository.deleteById(id);
    }

    private SupplierResponseDTO mapToDTO(NationalSupplier supplier) {
        return SupplierResponseDTO.builder()
                .id(supplier.getId())
                .companyName(supplier.getCompanyName())
                .cnpj(supplier.getCnpj())
                .supplyType(supplier.getSupplyType())
                .isApproved(supplier.getIsApproved())
                .build();
    }
}
