package com.aquasertao.api.modules.billing.services;

import com.aquasertao.api.modules.billing.dtos.SubscriptionRequestDTO;
import com.aquasertao.api.modules.billing.dtos.SubscriptionResponseDTO;
import com.aquasertao.api.modules.billing.models.Invoice;
import com.aquasertao.api.modules.billing.models.SaaSPlan;
import com.aquasertao.api.modules.billing.models.Subscription;
import com.aquasertao.api.modules.billing.repositories.InvoiceRepository;
import com.aquasertao.api.modules.billing.repositories.SaaSPlanRepository;
import com.aquasertao.api.modules.billing.repositories.SubscriptionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BillingServiceTest {

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private SaaSPlanRepository saasPlanRepository;

    @Mock
    private InvoiceRepository invoiceRepository;

    @InjectMocks
    private BillingService billingService;

    private UUID farmId;
    private UUID planId;
    private SubscriptionRequestDTO requestDTO;
    private SaaSPlan saasPlan;

    @BeforeEach
    void setUp() {
        farmId = UUID.randomUUID();
        planId = UUID.randomUUID();

        requestDTO = SubscriptionRequestDTO.builder()
                .farmId(farmId)
                .planId(planId)
                .build();

        saasPlan = SaaSPlan.builder()
                .id(planId)
                .name("Pro Plan")
                .maxTanks(10)
                .maxUsers(5)
                .priceMonthly(new BigDecimal("99.90"))
                .build();
    }

    @Test
    void subscribeFarm_ShouldCreateSubscriptionAndInvoice() {
        // Arrange
        when(saasPlanRepository.findById(planId)).thenReturn(Optional.of(saasPlan));
        when(subscriptionRepository.findByFarmIdAndStatus(farmId, "ACTIVE")).thenReturn(Optional.empty());
        
        when(subscriptionRepository.save(any(Subscription.class))).thenAnswer(i -> {
            Subscription s = i.getArgument(0);
            s.setId(UUID.randomUUID());
            return s;
        });

        // Act
        SubscriptionResponseDTO response = billingService.subscribeFarm(requestDTO);

        // Assert
        assertNotNull(response);
        assertEquals("ACTIVE", response.getStatus());
        assertEquals(planId, response.getPlanId());

        verify(subscriptionRepository).save(any(Subscription.class));
        
        // Verify an Invoice was generated for the exact price of the plan
        verify(invoiceRepository).save(argThat(invoice -> 
            invoice.getAmount().equals(new BigDecimal("99.90")) &&
            invoice.getStatus().equals("PENDING")
        ));
    }

    @Test
    void subscribeFarm_ShouldThrowException_WhenFarmAlreadyHasActiveSubscription() {
        // Arrange
        when(saasPlanRepository.findById(planId)).thenReturn(Optional.of(saasPlan));
        when(subscriptionRepository.findByFarmIdAndStatus(farmId, "ACTIVE"))
                .thenReturn(Optional.of(new Subscription()));

        // Act & Assert
        IllegalStateException exception = assertThrows(IllegalStateException.class, 
            () -> billingService.subscribeFarm(requestDTO));
            
        assertEquals("Farm already has an active subscription.", exception.getMessage());
        
        verify(subscriptionRepository, never()).save(any(Subscription.class));
        verify(invoiceRepository, never()).save(any(Invoice.class));
    }
}
