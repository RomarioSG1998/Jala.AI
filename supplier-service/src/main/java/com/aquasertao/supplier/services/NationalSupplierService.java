package com.aquasertao.supplier.services;

import com.aquasertao.supplier.config.RabbitMQConfig;
import com.aquasertao.supplier.dtos.SupplierRequestDTO;
import com.aquasertao.supplier.dtos.SupplierResponseDTO;
import com.aquasertao.supplier.events.SupplierApprovedEvent;
import com.aquasertao.supplier.models.NationalSupplier;
import com.aquasertao.supplier.repositories.NationalSupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

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
                .isApproved(false) // Needs SaaS Admin approval
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
                .orElseThrow(() -> new IllegalArgumentException("Supplier not found"));
        supplier.setIsApproved(true);
        NationalSupplier saved = nationalSupplierRepository.save(supplier);

        // Publish event to RabbitMQ
        SupplierApprovedEvent event = SupplierApprovedEvent.builder()
                .supplierId(saved.getId())
                .companyName(saved.getCompanyName())
                .cnpj(saved.getCnpj())
                .supplyType(saved.getSupplyType())
                .build();
        rabbitTemplate.convertAndSend(RabbitMQConfig.EXCHANGE_NAME, RabbitMQConfig.ROUTING_KEY, event);

        return mapToDTO(saved);
    }

    public void deleteSupplier(UUID id) {
        if (!nationalSupplierRepository.existsById(id)) {
            throw new IllegalArgumentException("Supplier not found");
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
