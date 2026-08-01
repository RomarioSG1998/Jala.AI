package com.aquasertao.api.modules.core.controllers;

import com.aquasertao.api.modules.core.dtos.AuthResponseDTO;
import com.aquasertao.api.modules.core.dtos.LoginRequestDTO;
import com.aquasertao.api.modules.core.dtos.RegisterRequestDTO;
import com.aquasertao.api.modules.core.dtos.ProfileImageDTO;
import com.aquasertao.api.modules.core.services.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponseDTO> register(
            @RequestBody RegisterRequestDTO request
    ) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDTO> login(
            @RequestBody LoginRequestDTO request
    ) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/google")
    public ResponseEntity<AuthResponseDTO> loginWithGoogle(
            @RequestBody com.aquasertao.api.modules.core.dtos.GoogleAuthRequestDTO request
    ) {
        return ResponseEntity.ok(authService.loginWithGoogle(request));
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("OK");
    }

    @GetMapping("/profile-image/{userId}")
    public ResponseEntity<ProfileImageDTO> getProfileImage(
            @PathVariable UUID userId
    ) {
        return ResponseEntity.ok(authService.getProfileImage(userId));
    }

    @PutMapping("/profile-image/{userId}")
    public ResponseEntity<Void> updateProfileImage(
            @PathVariable UUID userId,
            @RequestBody ProfileImageDTO request
    ) {
        authService.updateProfileImage(userId, request);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/profile/{userId}")
    public ResponseEntity<AuthResponseDTO> updateProfile(
            @PathVariable UUID userId,
            @RequestBody com.aquasertao.api.modules.core.dtos.UpdateProfileRequestDTO request
    ) {
        return ResponseEntity.ok(authService.updateProfile(userId, request));
    }
}
