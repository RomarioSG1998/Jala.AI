package com.aquasertao.api.modules.core.services;

import com.aquasertao.api.modules.core.dtos.AuthResponseDTO;
import com.aquasertao.api.modules.core.dtos.LoginRequestDTO;
import com.aquasertao.api.modules.core.dtos.RegisterRequestDTO;
import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.core.security.JwtService;
import com.aquasertao.api.modules.tenant.models.FarmTenant;
import com.aquasertao.api.modules.tenant.models.UserFarmLink;
import com.aquasertao.api.modules.tenant.repositories.FarmTenantRepository;
import com.aquasertao.api.modules.tenant.repositories.UserFarmLinkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.aquasertao.api.modules.core.dtos.ProfileImageDTO;
import com.aquasertao.api.modules.core.dtos.UpdateProfileRequestDTO;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final GlobalUserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final UserFarmLinkRepository userFarmLinkRepository;
    private final FarmTenantRepository farmTenantRepository;

    private UUID createFarmTenantForUser(GlobalUser user) {
        String cleanName = (user.getName() != null && !user.getName().isBlank()) ? user.getName() : "Fazenda";
        String uniqueSuffix = UUID.randomUUID().toString().replace("-", "").substring(0, 14);
        FarmTenant tenant = FarmTenant.builder()
                .name("Fazenda de " + cleanName)
                .cnpj("FT-" + uniqueSuffix)
                .ownerId(user.getId())
                .createdAt(LocalDateTime.now())
                .build();
        FarmTenant savedTenant = farmTenantRepository.saveAndFlush(tenant);

        UserFarmLink link = UserFarmLink.builder()
                .userId(user.getId())
                .farmId(savedTenant.getId())
                .accessRole("FARM_OWNER")
                .build();
        userFarmLinkRepository.save(link);
        return savedTenant.getId();
    }

    @Transactional
    public AuthResponseDTO register(RegisterRequestDTO request) {
        String cleanEmail = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : "";
        if (repository.findByEmailIgnoreCase(cleanEmail).isPresent()) {
            throw new IllegalArgumentException("Email already registered.");
        }

        String accountType = "SUPPLIER".equalsIgnoreCase(request.getAccountType()) ? "SUPPLIER" : "CLIENT";

        var user = GlobalUser.builder()
                .name(request.getName())
                .email(cleanEmail)
                .password(passwordEncoder.encode(request.getPassword()))
                .accountType(accountType)
                .createdAt(LocalDateTime.now())
                .build();
        
        GlobalUser savedUser = repository.save(user);

        UUID farmId = null;
        // Create unique isolated farm tenant for CLIENT user
        if ("CLIENT".equals(accountType)) {
            farmId = createFarmTenantForUser(savedUser);
        }

        var jwtToken = jwtService.generateToken(savedUser);
        
        return AuthResponseDTO.builder()
                .token(jwtToken)
                .email(savedUser.getEmail())
                .name(savedUser.getName())
                .accountType(savedUser.getAccountType())
                .userId(savedUser.getId())
                .farmId(farmId)
                .build();
    }

    @Transactional
    public AuthResponseDTO login(LoginRequestDTO request) {
        String cleanEmail = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : "";
        String cleanPassword = request.getPassword() != null ? request.getPassword().trim() : "";
        GlobalUser user = repository.findByEmailIgnoreCase(cleanEmail)
                .orElseGet(() -> repository.findByEmail(request.getEmail())
                        .orElseThrow(() -> new IllegalArgumentException("Credenciais inválidas.")));

        if (!user.isEnabled() || Boolean.FALSE.equals(user.getActive())) {
            throw new IllegalArgumentException("Sua conta está desativada. Entre em contato com o suporte do sistema.");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        user.getEmail(),
                        cleanPassword
                )
        );
        
        var jwtToken = jwtService.generateToken(user);
        
        return AuthResponseDTO.builder()
                .token(jwtToken)
                .email(user.getEmail())
                .name(user.getName())
                .accountType(user.getAccountType())
                .userId(user.getId())
                .farmId(getUserFarmId(user.getId()))
                .build();
    }

    @Transactional
    public AuthResponseDTO loginWithGoogle(com.aquasertao.api.modules.core.dtos.GoogleAuthRequestDTO request) {
        String email = request.getEmail();
        String name = request.getName();
        String photoUrl = request.getPhotoUrl();

        if (email == null || email.trim().isEmpty()) {
            throw new IllegalArgumentException("E-mail do Google não informado.");
        }

        final String finalEmail = email.toLowerCase().trim();
        final String finalName = (name != null && !name.trim().isEmpty()) ? name.trim() : "Usuário Google";
        final String requestedAccountType = "SUPPLIER".equalsIgnoreCase(request.getAccountType()) ? "SUPPLIER" : "CLIENT";

        java.util.Optional<GlobalUser> existingUserOpt = repository.findByEmailIgnoreCase(finalEmail);
        boolean isNewUser = existingUserOpt.isEmpty();

        GlobalUser user = existingUserOpt.orElseGet(() -> {
            GlobalUser newUser = GlobalUser.builder()
                    .name(finalName)
                    .email(finalEmail)
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .accountType(requestedAccountType)
                    .profileImage(photoUrl)
                    .createdAt(LocalDateTime.now())
                    .active(true)
                    .build();
            GlobalUser saved = repository.save(newUser);

            if ("CLIENT".equals(requestedAccountType)) {
                createFarmTenantForUser(saved);
            }
            return saved;
        });

        if (!user.isEnabled() || Boolean.FALSE.equals(user.getActive())) {
            throw new IllegalArgumentException("Sua conta está desativada. Entre em contato com o suporte do sistema.");
        }

        // Ensure accountType is defined if missing
        if (user.getAccountType() == null || user.getAccountType().isBlank()) {
            user.setAccountType(requestedAccountType);
            user = repository.save(user);
        }

        if ((user.getProfileImage() == null || user.getProfileImage().isBlank()) && photoUrl != null && !photoUrl.isBlank()) {
            user.setProfileImage(photoUrl);
            user = repository.save(user);
        }

        // Ensure FarmTenant exists for CLIENT users
        UUID farmId = getUserFarmId(user.getId());

        var jwtToken = jwtService.generateToken(user);

        return AuthResponseDTO.builder()
                .token(jwtToken)
                .email(user.getEmail())
                .name(user.getName())
                .accountType(user.getAccountType())
                .userId(user.getId())
                .farmId(farmId)
                .isNewUser(isNewUser)
                .build();
    }

     public ProfileImageDTO getProfileImage(UUID userId) {
         var user = repository.findById(userId)
                 .orElseThrow(() -> new IllegalArgumentException("User not found."));
         return ProfileImageDTO.builder()
                 .profileImage(user.getProfileImage())
                 .build();
     }

     public void updateProfileImage(UUID userId, ProfileImageDTO dto) {
         var user = repository.findById(userId)
                 .orElseThrow(() -> new IllegalArgumentException("User not found."));
         user.setProfileImage(dto.getProfileImage());
         repository.save(user);
     }

     @Transactional
     public AuthResponseDTO updateProfile(UUID userId, UpdateProfileRequestDTO request) {
         var user = repository.findById(userId)
                 .orElseThrow(() -> new IllegalArgumentException("User not found."));

         if (!user.getEmail().equalsIgnoreCase(request.getEmail())) {
             if (repository.findByEmail(request.getEmail()).isPresent()) {
                 throw new IllegalArgumentException("Email already registered.");
             }
             user.setEmail(request.getEmail());
         }

         user.setName(request.getName());

         if (request.getPassword() != null && !request.getPassword().trim().isEmpty()) {
             user.setPassword(passwordEncoder.encode(request.getPassword()));
         }

         GlobalUser updatedUser = repository.save(user);
         
         var jwtToken = jwtService.generateToken(updatedUser);

         return AuthResponseDTO.builder()
                 .token(jwtToken)
                 .email(updatedUser.getEmail())
                 .name(updatedUser.getName())
                 .accountType(updatedUser.getAccountType())
                 .userId(updatedUser.getId())
                 .farmId(getUserFarmId(updatedUser.getId()))
                 .build();
     }

     @Transactional
     private UUID getUserFarmId(UUID userId) {
         try {
             GlobalUser user = repository.findById(userId).orElse(null);
             if (user == null) {
                 return null;
             }

             if (user.getAccountType() == null || user.getAccountType().isBlank()) {
                 user.setAccountType("CLIENT");
                 user = repository.save(user);
             }

             if (!"CLIENT".equalsIgnoreCase(user.getAccountType().trim())) {
                 return null;
             }

             UUID defaultFarmId = UUID.fromString("55555555-5555-5555-5555-555555555555");
             List<UserFarmLink> links = userFarmLinkRepository.findByUserId(userId);
             if (links == null || links.isEmpty()) {
                 return createFarmTenantForUser(user);
             }

             UserFarmLink existingLink = links.get(0);

             // CRITICAL: If the user is linked to the legacy default farm ID or a non-existent farm, create farm tenant and update link
             if (defaultFarmId.equals(existingLink.getFarmId()) || !farmTenantRepository.existsById(existingLink.getFarmId())) {
                 userFarmLinkRepository.deleteByUserIdAndFarmId(userId, existingLink.getFarmId());
                 return createFarmTenantForUser(user);
             }

             return existingLink.getFarmId();
         } catch (Exception e) {
             log.warn("Could not retrieve farmId for userId {}: {}", userId, e.getMessage());
             return null;
         }
     }
}
