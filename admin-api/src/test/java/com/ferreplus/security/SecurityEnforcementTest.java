package com.ferreplus.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Enforcement de @PreAuthorize (R2-R8): sin token → 401; autenticado sin
 * permiso → 403 JSON; con permiso → 200. También cubre el contrato de login
 * (permisos en AuthResponseDTO). @Transactional: cada test revierte, y las
 * peticiones MockMvc corren en el mismo hilo → participan de la transacción.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class SecurityEnforcementTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void sinAutenticacion_devuelve401() throws Exception {
        mockMvc.perform(get("/api/productos"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = "VENTAS_VER")
    void sinPermisoDelModulo_devuelve403() throws Exception {
        mockMvc.perform(get("/api/productos"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "PRODUCTOS_VER")
    void conPermiso_devuelve200() throws Exception {
        mockMvc.perform(get("/api/productos"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = {"PRODUCTOS_VER", "PRODUCTOS_CREAR"})
    void conPermisoDeEscritura_devuelve200() throws Exception {
        mockMvc.perform(post("/api/productos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"nombre":"Producto Enforcement","precioCompra":5,"precioVenta":10,"stockActual":10}
                                """))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = "PRODUCTOS_VER")
    void sinPermisoDeEscritura_devuelve403() throws Exception {
        mockMvc.perform(post("/api/productos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"nombre":"Producto Enforcement","precioCompra":5,"precioVenta":10,"stockActual":10}
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLES_VER")
    void catalogoDisponibleParaQuienGestionaRoles() throws Exception {
        mockMvc.perform(get("/api/modulos"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = "VENTAS_VER")
    void catalogoDenegadoSinPermisosDeGestion() throws Exception {
        mockMvc.perform(get("/api/modulos"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "DASHBOARD_VER")
    void loginEsPublico_yDevuelvePermisosEfectivos() throws Exception {
        String body = objectMapper.writeValueAsString(
                java.util.Map.of("email", "admin@ferreplus.com", "password", "admin123"));

        String response = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.email").value("admin@ferreplus.com"))
                .andExpect(jsonPath("$.rol").value("ADMIN"))
                .andExpect(jsonPath("$.permisos.length()").value(45))
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode json = objectMapper.readTree(response);
        JsonNode permisos = json.get("permisos");
        for (int i = 0; i < permisos.size(); i++) {
            if (permisos.get(i).asText().startsWith("ROLE_")) {
                throw new AssertionError("Login no debe exponer autoridades ROLE_ en permisos");
            }
        }
    }
}
