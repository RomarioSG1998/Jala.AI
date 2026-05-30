package com.aquasertao.api.modules.operational.controllers;

import com.aquasertao.api.modules.operational.services.TankService;
import com.aquasertao.api.modules.core.security.JwtAuthenticationFilter;
import com.aquasertao.api.modules.core.security.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class TankControllerSecurityTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @org.junit.jupiter.api.Test
    void createTank_ShouldReturn401_WhenUnauthenticated() throws Exception {
        mockMvc.perform(post("/api/tanks")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"farmId\":\"123e4567-e89b-12d3-a456-426614174000\", \"name\":\"Tank 1\", \"fishCapacity\":1000}"))
                .andExpect(status().isForbidden());
    }

    @org.junit.jupiter.api.Test
    void getTanksByFarmId_ShouldReturn401_WhenUnauthenticated() throws Exception {
        mockMvc.perform(get("/api/tanks/farm/123e4567-e89b-12d3-a456-426614174000"))
                .andExpect(status().isForbidden());
    }
}
