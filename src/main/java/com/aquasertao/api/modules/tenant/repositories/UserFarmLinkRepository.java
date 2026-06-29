package com.aquasertao.api.modules.tenant.repositories;

import com.aquasertao.api.modules.tenant.models.UserFarmLink;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserFarmLinkRepository extends JpaRepository<UserFarmLink, UserFarmLink.UserFarmLinkId> {
    List<UserFarmLink> findByFarmId(UUID farmId);
    List<UserFarmLink> findByFarmIdAndAccessRole(UUID farmId, String accessRole);
    List<UserFarmLink> findByUserId(UUID userId);
    void deleteByUserIdAndFarmId(UUID userId, UUID farmId);
}
