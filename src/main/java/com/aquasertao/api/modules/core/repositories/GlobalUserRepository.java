package com.aquasertao.api.modules.core.repositories;

import com.aquasertao.api.modules.core.models.GlobalUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface GlobalUserRepository extends JpaRepository<GlobalUser, UUID> {
    Optional<GlobalUser> findByEmail(String email);
    Optional<GlobalUser> findByEmailIgnoreCase(String email);
    java.util.List<GlobalUser> findByAccountType(String accountType);
}
