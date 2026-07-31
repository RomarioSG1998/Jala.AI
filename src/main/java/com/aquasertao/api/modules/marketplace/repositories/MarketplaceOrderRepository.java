package com.aquasertao.api.modules.marketplace.repositories;

import com.aquasertao.api.modules.marketplace.models.MarketplaceOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MarketplaceOrderRepository extends JpaRepository<MarketplaceOrder, UUID> {
    List<MarketplaceOrder> findByBuyerFarmIdOrderByCreatedAtDesc(UUID buyerFarmId);
    List<MarketplaceOrder> findBySellerFarmIdOrderByCreatedAtDesc(UUID sellerFarmId);
    Optional<MarketplaceOrder> findByStripePaymentIntentId(String paymentIntentId);
}
