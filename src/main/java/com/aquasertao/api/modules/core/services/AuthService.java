package com.aquasertao.api.modules.core.services;

import com.aquasertao.api.modules.core.dtos.AuthResponseDTO;
import com.aquasertao.api.modules.core.dtos.LoginRequestDTO;
import com.aquasertao.api.modules.core.dtos.RegisterRequestDTO;
import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.core.security.JwtService;
import com.aquasertao.api.modules.tenant.models.UserFarmLink;
import com.aquasertao.api.modules.tenant.repositories.UserFarmLinkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.aquasertao.api.modules.core.dtos.ProfileImageDTO;
import com.aquasertao.api.modules.core.dtos.UpdateProfileRequestDTO;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final GlobalUserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final UserFarmLinkRepository userFarmLinkRepository;

    public AuthResponseDTO register(RegisterRequestDTO request) {
        if (repository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email already registered.");
        }

        String accountType = "SUPPLIER".equalsIgnoreCase(request.getAccountType()) ? "SUPPLIER" : "CLIENT";

        var user = GlobalUser.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .accountType(accountType)
                .createdAt(LocalDateTime.now())
                .build();
        
        GlobalUser savedUser = repository.save(user);

        UUID farmId = null;
        // Create unique isolated farm tenant for CLIENT user
        if ("CLIENT".equals(accountType)) {
            UUID userFarmId = UUID.randomUUID();
            UserFarmLink link = UserFarmLink.builder()
                    .userId(savedUser.getId())
                    .farmId(userFarmId)
                    .accessRole("FARM_OWNER")
                    .build();
            userFarmLinkRepository.save(link);
            farmId = userFarmId;
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

    public AuthResponseDTO login(LoginRequestDTO request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );
        
        var user = repository.findByEmail(request.getEmail())
                .orElseThrow();
        
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

        java.util.Optional<GlobalUser> existingUserOpt = repository.findByEmail(finalEmail);
        boolean isNewUser = existingUserOpt.isEmpty();

        GlobalUser user = existingUserOpt.orElseGet(() -> {
            GlobalUser newUser = GlobalUser.builder()
                    .name(finalName)
                    .email(finalEmail)
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .accountType(requestedAccountType)
                    .profileImage(photoUrl)
                    .createdAt(LocalDateTime.now())
                    .build();
            GlobalUser saved = repository.save(newUser);

            if ("CLIENT".equals(requestedAccountType)) {
                UUID userFarmId = UUID.randomUUID();
                UserFarmLink link = UserFarmLink.builder()
                        .userId(saved.getId())
                        .farmId(userFarmId)
                        .accessRole("FARM_OWNER")
                        .build();
                userFarmLinkRepository.save(link);
            }
            return saved;
        });

        if ((user.getProfileImage() == null || user.getProfileImage().isBlank()) && photoUrl != null && !photoUrl.isBlank()) {
            user.setProfileImage(photoUrl);
            user = repository.save(user);
        }

        var jwtToken = jwtService.generateToken(user);

        return AuthResponseDTO.builder()
                .token(jwtToken)
                .email(user.getEmail())
                .name(user.getName())
                .accountType(user.getAccountType())
                .userId(user.getId())
                .farmId(getUserFarmId(user.getId()))
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

     private UUID getUserFarmId(UUID userId) {
         return userFarmLinkRepository.findByUserId(userId).stream()
                 .map(UserFarmLink::getFarmId)
                 .findFirst()
                 .orElseGet(() -> {
                     UUID newFarmId = UUID.randomUUID();
                     UserFarmLink link = UserFarmLink.builder()
                             .userId(userId)
                             .farmId(newFarmId)
                             .accessRole("FARM_OWNER")
                             .build();
                     userFarmLinkRepository.save(link);
                     return newFarmId;
                 });
     }
}
