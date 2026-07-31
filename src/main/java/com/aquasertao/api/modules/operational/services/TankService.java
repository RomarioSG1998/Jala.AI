package com.aquasertao.api.modules.operational.services;

import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import com.aquasertao.api.modules.operational.dtos.TankRequestDTO;
import com.aquasertao.api.modules.operational.dtos.TankResponseDTO;
import com.aquasertao.api.modules.operational.models.Tank;
import com.aquasertao.api.modules.operational.repositories.TankRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TankService {

    // ── Plan guard ─────────────────────────────────────────────────────────────
    /** Thrown when the farm's tank count exceeds the plan limit. */
    public static class PlanLimitExceededException extends RuntimeException {
        private final int maxAllowed;
        public PlanLimitExceededException(int maxAllowed) {
            super("PLAN_LIMIT_EXCEEDED:" + maxAllowed);
            this.maxAllowed = maxAllowed;
        }
        public int getMaxAllowed() { return maxAllowed; }
    }

    private final TankRepository tankRepository;
    private final SubscriptionRepository subscriptionRepository;
    private final SaaSPlanRepository saasPlanRepository;

    /** Returns the max tanks allowed for this farm based on its active plan. FREE default = 3. */
    private int getMaxTanksAllowed(UUID farmId) {
        return subscriptionRepository.findByFarmIdAndStatus(farmId, "ACTIVE")
                .map(sub -> saasPlanRepository.findById(sub.getPlanId())
                        .map(plan -> plan.getMaxTanks())
                        .orElse(3))
                .orElse(3);
    }

    public TankResponseDTO createTank(TankRequestDTO requestDTO) {
        // ── Plan limit guard ──────────────────────────────────────────────────
        List<Tank> existing = tankRepository.findByFarmId(requestDTO.getFarmId());
        int maxAllowed = getMaxTanksAllowed(requestDTO.getFarmId());
        if (existing.size() >= maxAllowed) {
            throw new PlanLimitExceededException(maxAllowed);
        }
        LocalDate harvestDate = null;
        if (requestDTO.getNextHarvestDate() != null && !requestDTO.getNextHarvestDate().isEmpty()) {
            try {
                harvestDate = LocalDate.parse(requestDTO.getNextHarvestDate());
            } catch (Exception e) {
                // Ignore or log
            }
        }

        LocalDate stockingDate = null;
        if (requestDTO.getStockingDate() != null && !requestDTO.getStockingDate().isEmpty()) {
            try {
                stockingDate = LocalDate.parse(requestDTO.getStockingDate());
            } catch (Exception e) {
                // Ignore or log
            }
        }

        Tank tank = Tank.builder()
                .farmId(requestDTO.getFarmId())
                .name(requestDTO.getName())
                .fishSpecies(requestDTO.getFishSpecies())
                .fishCapacity(requestDTO.getFishCapacity())
                .averageWeightG(requestDTO.getAverageWeightG() != null ? requestDTO.getAverageWeightG() : 0)
                .mortalityCount(requestDTO.getMortalityCount() != null ? requestDTO.getMortalityCount() : 0)
                .nextHarvestDate(harvestDate)
                .stockingDate(stockingDate)
                .initialStockingQty(requestDTO.getInitialStockingQty())
                .initialAverageWeightG(requestDTO.getInitialAverageWeightG())
                .supplier(requestDTO.getSupplier())
                .status(requestDTO.getStatus() != null ? requestDTO.getStatus() : "ACTIVE")
                .customImage(requestDTO.getCustomImage())
                .build();

        Tank savedTank = tankRepository.save(tank);
        return mapToDTO(savedTank);
    }

    public Page<TankResponseDTO> getTanksByFarmId(UUID farmId, Pageable pageable) {
        Page<Tank> tankPage = tankRepository.findByFarmId(farmId, pageable);
        return tankPage.map(this::mapToDTO);
    }

    public TankResponseDTO getById(UUID id, UUID farmId) {
        Tank tank = tankRepository.findByIdAndFarmId(id, farmId)
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied"));
        return mapToDTO(tank);
    }

    public TankResponseDTO updateTank(UUID id, TankRequestDTO requestDTO) {
        Tank existingTank = tankRepository.findByIdAndFarmId(id, requestDTO.getFarmId())
                .orElseThrow(() -> new IllegalArgumentException("Tank not found or access denied"));

        existingTank.setName(requestDTO.getName());
        existingTank.setFishSpecies(requestDTO.getFishSpecies());
        existingTank.setFishCapacity(requestDTO.getFishCapacity());
        existingTank.setAverageWeightG(requestDTO.getAverageWeightG() != null ? requestDTO.getAverageWeightG() : existingTank.getAverageWeightG());
        existingTank.setMortalityCount(requestDTO.getMortalityCount() != null ? requestDTO.getMortalityCount() : existingTank.getMortalityCount());
        existingTank.setInitialStockingQty(requestDTO.getInitialStockingQty());
        existingTank.setInitialAverageWeightG(requestDTO.getInitialAverageWeightG());
        existingTank.setSupplier(requestDTO.getSupplier());
        
        if (requestDTO.getNextHarvestDate() != null) {
            if (requestDTO.getNextHarvestDate().isEmpty()) {
                existingTank.setNextHarvestDate(null);
            } else {
                try {
                    existingTank.setNextHarvestDate(LocalDate.parse(requestDTO.getNextHarvestDate()));
                } catch (Exception e) {
                    // Ignore or log
                }
            }
        }
        if (requestDTO.getStockingDate() != null) {
            if (requestDTO.getStockingDate().isEmpty()) {
                existingTank.setStockingDate(null);
            } else {
                try {
                    existingTank.setStockingDate(LocalDate.parse(requestDTO.getStockingDate()));
                } catch (Exception e) {
                    // Ignore or log
                }
            }
        }
        if (requestDTO.getStatus() != null) {
            existingTank.setStatus(requestDTO.getStatus());
        }
        if (requestDTO.getCustomImage() != null) {
            existingTank.setCustomImage(requestDTO.getCustomImage().isEmpty() ? null : requestDTO.getCustomImage());
        }

        Tank updatedTank = tankRepository.save(existingTank);
        return mapToDTO(updatedTank);
    }

    public void deleteTank(UUID id, UUID farmId) {
        if (!tankRepository.existsByIdAndFarmId(id, farmId)) {
            throw new IllegalArgumentException("Tank not found or access denied");
        }
        tankRepository.deleteById(id);
    }

    private TankResponseDTO mapToDTO(Tank tank) {
        return TankResponseDTO.builder()
                .id(tank.getId())
                .farmId(tank.getFarmId())
                .name(tank.getName())
                .fishSpecies(tank.getFishSpecies())
                .fishCapacity(tank.getFishCapacity())
                .averageWeightG(tank.getAverageWeightG())
                .mortalityCount(tank.getMortalityCount())
                .nextHarvestDate(tank.getNextHarvestDate())
                .stockingDate(tank.getStockingDate())
                .initialStockingQty(tank.getInitialStockingQty())
                .initialAverageWeightG(tank.getInitialAverageWeightG())
                .supplier(tank.getSupplier())
                .status(tank.getStatus())
                .customImage(tank.getCustomImage())
                .build();
    }
}
