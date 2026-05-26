package com.aquasertao.api.modules.strategic.repositories;

import com.aquasertao.api.modules.strategic.models.FinancialTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface FinancialTransactionRepository extends JpaRepository<FinancialTransaction, UUID> {

    Page<FinancialTransaction> findByFarmId(UUID farmId, Pageable pageable);

    Optional<FinancialTransaction> findByIdAndFarmId(UUID id, UUID farmId);

    boolean existsByIdAndFarmId(UUID id, UUID farmId);
}
