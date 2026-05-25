package com.aquasertao.api.modules.billing.repositories;

import com.aquasertao.api.modules.billing.models.Invoice;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, UUID> {
    
    // Fetch all invoices for a specific subscription
    Page<Invoice> findBySubscriptionId(UUID subscriptionId, Pageable pageable);
}
