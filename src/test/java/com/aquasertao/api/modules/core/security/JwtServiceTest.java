package com.aquasertao.api.modules.core.security;

import com.aquasertao.api.modules.core.models.GlobalUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JwtServiceTest {

    private JwtService jwtService;
    private GlobalUser mockUser;

    @BeforeEach
    void setUp() {
        // We initialize the JwtService directly and inject the @Value fields
        jwtService = new JwtService();
        org.springframework.test.util.ReflectionTestUtils.setField(jwtService, "secretKey", "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970");
        org.springframework.test.util.ReflectionTestUtils.setField(jwtService, "jwtExpiration", 86400000L);
        
        mockUser = GlobalUser.builder()
                .email("test@domain.com")
                .build();
    }

    @Test
    void generateToken_ShouldReturnValidToken() {
        // Act
        String token = jwtService.generateToken(mockUser);

        // Assert
        assertNotNull(token);
        assertFalse(token.isEmpty());
        // A valid JWT always has two dots (Header.Payload.Signature)
        assertEquals(2, token.chars().filter(ch -> ch == '.').count());
    }

    @Test
    void extractUsername_ShouldReturnEmailFromToken() {
        // Arrange
        String token = jwtService.generateToken(mockUser);

        // Act
        String extractedEmail = jwtService.extractUsername(token);

        // Assert
        assertEquals("test@domain.com", extractedEmail);
    }

    @Test
    void isTokenValid_ShouldReturnTrueForValidToken() {
        // Arrange
        String token = jwtService.generateToken(mockUser);

        // Act
        boolean isValid = jwtService.isTokenValid(token, mockUser);

        // Assert
        assertTrue(isValid);
    }
}
