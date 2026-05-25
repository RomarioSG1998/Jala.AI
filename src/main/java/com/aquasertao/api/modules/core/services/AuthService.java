package com.aquasertao.api.modules.core.services;

import com.aquasertao.api.modules.core.dtos.AuthResponseDTO;
import com.aquasertao.api.modules.core.dtos.LoginRequestDTO;
import com.aquasertao.api.modules.core.dtos.RegisterRequestDTO;
import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.core.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final GlobalUserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public AuthResponseDTO register(RegisterRequestDTO request) {
        if (repository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email already registered.");
        }

        var user = GlobalUser.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .accountType(request.getAccountType())
                .createdAt(LocalDateTime.now())
                .build();
        
        repository.save(user);
        var jwtToken = jwtService.generateToken(user);
        
        return AuthResponseDTO.builder()
                .token(jwtToken)
                .email(user.getEmail())
                .accountType(user.getAccountType())
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
                .build();
    }
}
