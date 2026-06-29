package com.aquasertao.api.modules.marketplace.services;

import com.aquasertao.api.modules.marketplace.dtos.AnnouncementRequestDTO;
import com.aquasertao.api.modules.marketplace.dtos.AnnouncementResponseDTO;
import com.aquasertao.api.modules.marketplace.models.Announcement;
import com.aquasertao.api.modules.marketplace.repositories.AnnouncementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AnnouncementService {

    private final AnnouncementRepository announcementRepository;

    @Transactional
    public AnnouncementResponseDTO create(AnnouncementRequestDTO dto) {
        Announcement a = Announcement.builder()
                .farmId(dto.getFarmId())
                .category(dto.getCategory().toUpperCase())
                .title(dto.getTitle())
                .description(dto.getDescription())
                .price(dto.getPrice())
                .sellerName(dto.getSellerName())
                .sellerPhone(dto.getSellerPhone())
                .sellerLocation(dto.getSellerLocation())
                .imageUrl(dto.getImageUrl())
                .active(true)
                .build();
        return toDTO(announcementRepository.save(a));
    }

    public List<AnnouncementResponseDTO> findAll(String category, String location) {
        List<Announcement> allActive = announcementRepository.findByActiveTrue();
        
        return allActive.stream()
                .filter(a -> {
                    if (category != null && !category.isBlank()) {
                        return category.equalsIgnoreCase(a.getCategory());
                    }
                    return true;
                })
                .filter(a -> {
                    if (location != null && !location.isBlank()) {
                        if (a.getSellerLocation() == null) return false;
                        return a.getSellerLocation().toLowerCase().contains(location.toLowerCase());
                    }
                    return true;
                })
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public List<AnnouncementResponseDTO> findByFarm(UUID farmId) {
        return announcementRepository.findByFarmIdAndActiveTrue(farmId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    @Transactional
    public AnnouncementResponseDTO update(UUID id, UUID farmId, AnnouncementRequestDTO dto) {
        Announcement a = announcementRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Announcement not found or access denied"));
        a.setTitle(dto.getTitle());
        a.setDescription(dto.getDescription());
        a.setPrice(dto.getPrice());
        a.setCategory(dto.getCategory().toUpperCase());
        a.setSellerPhone(dto.getSellerPhone());
        a.setSellerLocation(dto.getSellerLocation());
        if (dto.getImageUrl() != null) a.setImageUrl(dto.getImageUrl());
        return toDTO(announcementRepository.save(a));
    }

    @Transactional
    public void deactivate(UUID id, UUID farmId) {
        Announcement a = announcementRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Announcement not found or access denied"));
        a.setActive(false);
        announcementRepository.save(a);
    }

    private AnnouncementResponseDTO toDTO(Announcement a) {
        return AnnouncementResponseDTO.builder()
                .id(a.getId())
                .farmId(a.getFarmId())
                .category(a.getCategory())
                .title(a.getTitle())
                .description(a.getDescription())
                .price(a.getPrice())
                .sellerName(a.getSellerName())
                .sellerPhone(a.getSellerPhone())
                .sellerLocation(a.getSellerLocation())
                .imageUrl(a.getImageUrl())
                .active(a.getActive())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
