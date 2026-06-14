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

        var user = GlobalUser.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .accountType("CLIENT")
                .createdAt(LocalDateTime.now())
                .build();
        
        GlobalUser savedUser = repository.save(user);

        // Link user to default farm tenant
        UUID defaultFarmId = UUID.fromString("55555555-5555-5555-5555-555555555555");
        UserFarmLink link = UserFarmLink.builder()
                .userId(savedUser.getId())
                .farmId(defaultFarmId)
                .accessRole("FARM_OWNER")
                .build();
        userFarmLinkRepository.save(link);

        var jwtToken = jwtService.generateToken(savedUser);
        
        return AuthResponseDTO.builder()
                .token(jwtToken)
                .email(savedUser.getEmail())
                .accountType(savedUser.getAccountType())
                .userId(savedUser.getId())
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
                .accountType(user.getAccountType())
                .userId(user.getId())
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
}
