package com.aquasertao.api.modules.marketplace.repositories;

import com.aquasertao.api.modules.marketplace.models.Announcement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AnnouncementRepository extends JpaRepository<Announcement, UUID> {

    List<Announcement> findByActiveTrue();

    List<Announcement> findByFarmIdAndActiveTrue(UUID farmId);

    List<Announcement> findByCategoryAndActiveTrue(String category);

    @Query("SELECT a FROM Announcement a WHERE a.active = true " +
           "AND (:category IS NULL OR a.category = :category) " +
           "AND (:location IS NULL OR LOWER(a.sellerLocation) LIKE LOWER(CONCAT('%', :location, '%')))")
    List<Announcement> findFiltered(
            @Param("category") String category,
            @Param("location") String location
    );

    Optional<Announcement> findByIdAndFarmId(UUID id, UUID farmId);
}
