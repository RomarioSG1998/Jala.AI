package com.aquasertao.api.modules.operational.repositories;

import com.aquasertao.api.modules.operational.models.Tank;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@Transactional
class TenantIsolationTest {

    @Autowired
    private TankRepository tankRepository;

    @Autowired
    private com.aquasertao.api.modules.tenant.repositories.FarmTenantRepository farmTenantRepository;

    @Autowired
    private com.aquasertao.api.modules.core.repositories.GlobalUserRepository globalUserRepository;

    @Test
    void findByFarmId_ShouldOnlyReturnTanksForSpecificFarm_IgnoringOthers() {
        // Arrange: Create a global user to be the owner
        com.aquasertao.api.modules.core.models.GlobalUser owner = new com.aquasertao.api.modules.core.models.GlobalUser();
        owner.setName("Test Owner");
        owner.setEmail("owner@test.com");
        owner.setPassword("password123");
        owner.setAccountType("FARM_OWNER");
        owner = globalUserRepository.save(owner);
        UUID ownerId = owner.getId();

        // Save Farm A
        com.aquasertao.api.modules.tenant.models.FarmTenant farmTenantA = new com.aquasertao.api.modules.tenant.models.FarmTenant();
        farmTenantA.setName("Farm A");
        farmTenantA.setCnpj("12345678000199");
        farmTenantA.setOwnerId(ownerId);
        farmTenantA = farmTenantRepository.save(farmTenantA);
        UUID farmA = farmTenantA.getId();

        // Save Farm B
        com.aquasertao.api.modules.tenant.models.FarmTenant farmTenantB = new com.aquasertao.api.modules.tenant.models.FarmTenant();
        farmTenantB.setName("Farm B");
        farmTenantB.setCnpj("98765432000111");
        farmTenantB.setOwnerId(ownerId);
        farmTenantB = farmTenantRepository.save(farmTenantB);
        UUID farmB = farmTenantB.getId();

        // Save 3 tanks for Farm A
        tankRepository.save(Tank.builder().farmId(farmA).name("Farm A - Tank 1").fishCapacity(1000).build());
        tankRepository.save(Tank.builder().farmId(farmA).name("Farm A - Tank 2").fishCapacity(1000).build());
        tankRepository.save(Tank.builder().farmId(farmA).name("Farm A - Tank 3").fishCapacity(1000).build());

        // Save 2 tanks for Farm B
        tankRepository.save(Tank.builder().farmId(farmB).name("Farm B - Tank 1").fishCapacity(500).build());
        tankRepository.save(Tank.builder().farmId(farmB).name("Farm B - Tank 2").fishCapacity(500).build());

        // Act: Query tanks ONLY for Farm A
        Page<Tank> resultsForFarmA = tankRepository.findByFarmId(farmA, PageRequest.of(0, 10));

        // Assert: Verify Tenant Isolation
        // Farm A should only see its 3 tanks, completely ignorant of Farm B's 2 tanks.
        assertEquals(3, resultsForFarmA.getTotalElements());
        
        // Ensure that none of the results belong to Farm B
        boolean hasLeakedData = resultsForFarmA.getContent().stream()
                .anyMatch(tank -> tank.getFarmId().equals(farmB));
        
        assertEquals(false, hasLeakedData, "CRITICAL SECURITY FAILURE: Data leaked across tenants!");
    }
}
