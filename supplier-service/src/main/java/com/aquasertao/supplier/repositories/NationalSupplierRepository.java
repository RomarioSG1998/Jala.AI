package com.aquasertao.supplier.repositories;

import com.aquasertao.supplier.models.NationalSupplier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface NationalSupplierRepository extends JpaRepository<NationalSupplier, UUID> {
}
