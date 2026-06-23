package com.aquasertao.api.modules.tenant.models;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.io.Serializable;
import java.util.UUID;

@Entity
@Table(name = "user_farm_link", schema = "auth_schema")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@IdClass(UserFarmLink.UserFarmLinkId.class)
public class UserFarmLink {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Id
    @Column(name = "farm_id")
    private UUID farmId;

    @Column(name = "access_role", nullable = false)
    private String accessRole; // FARM_OWNER, MANAGER, FIELD_WORKER

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserFarmLinkId implements Serializable {
        private UUID userId;
        private UUID farmId;
    }
}
