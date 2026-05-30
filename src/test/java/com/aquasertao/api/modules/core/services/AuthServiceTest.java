package com.aquasertao.api.modules.core.services;

import com.aquasertao.api.modules.core.dtos.AuthResponseDTO;
import com.aquasertao.api.modules.core.dtos.RegisterRequestDTO;
import com.aquasertao.api.modules.core.models.GlobalUser;
import com.aquasertao.api.modules.core.repositories.GlobalUserRepository;
import com.aquasertao.api.modules.core.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private GlobalUserRepository repository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private AuthenticationManager authenticationManager;

    @InjectMocks
    private AuthService authService;

    private RegisterRequestDTO registerRequest;

    @BeforeEach
    void setUp() {
        registerRequest = RegisterRequestDTO.builder()
                .name("John Doe")
                .email("john.doe@test.com")
                .password("securePassword123")
                .build();
    }

    @Test
    void register_ShouldSaveUserAndReturnToken() {
        // Arrange
        when(repository.findByEmail(anyString())).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("encodedPassword");
        when(repository.save(any(GlobalUser.class))).thenAnswer(i -> i.getArguments()[0]);
        when(jwtService.generateToken(any(GlobalUser.class))).thenReturn("mockJwtToken");

        // Act
        AuthResponseDTO response = authService.register(registerRequest);

        // Assert
        assertNotNull(response);
        assertEquals("mockJwtToken", response.getToken());
        verify(passwordEncoder).encode("securePassword123");
        verify(repository).save(any(GlobalUser.class));
        verify(jwtService).generateToken(any(GlobalUser.class));
    }

    @Test
    void register_ShouldThrowException_WhenEmailAlreadyExists() {
        // Arrange
        when(repository.findByEmail(registerRequest.getEmail()))
                .thenReturn(Optional.of(new GlobalUser()));

        // Act & Assert
        assertThrows(IllegalArgumentException.class, () -> authService.register(registerRequest));
        verify(repository, never()).save(any(GlobalUser.class));
    }
}
