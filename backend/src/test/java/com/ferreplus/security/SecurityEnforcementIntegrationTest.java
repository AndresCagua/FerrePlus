package com.ferreplus.security;

import com.ferreplus.dto.AuthLoginDTO;
import com.ferreplus.dto.AuthResponseDTO;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.service.AuthService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * R9.2/R5/R2 — Enforcement con tokens JWT reales: se crea un usuario VENDEDOR,
 * se loguea por {@link AuthService}, y se ejercitan endpoints con el token en
 * el header Authorization. La matriz confirmada del seed restringe de verdad.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class SecurityEnforcementIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private String tokenVendedor;
    private String tokenAdmin;

    @AfterEach
    void clearContext() {
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
    }

    private String tokenVendedor() {
        if (tokenVendedor == null) {
            Rol vendedor = rolRepository.findByNombre("VENDEDOR").orElseThrow();
            usuarioRepository.save(Usuario.builder()
                    .nombre("Vendedor Token")
                    .email("vendedor-token@ferreplus.com")
                    .password(passwordEncoder.encode("password123"))
                    .rol(vendedor)
                    .activo(true)
                    .build());
            tokenVendedor = login("vendedor-token@ferreplus.com", "password123");
        }
        return tokenVendedor;
    }

    private String tokenAdmin() {
        if (tokenAdmin == null) {
            tokenAdmin = login("admin@ferreplus.com", "admin123");
        }
        return tokenAdmin;
    }

    private String login(String email, String password) {
        AuthLoginDTO dto = new AuthLoginDTO();
        dto.setEmail(email);
        dto.setPassword(password);
        AuthResponseDTO response = authService.login(dto);
        return response.getToken();
    }

    @Test
    void vendedor_sinGASTOS_VER_recibe403() throws Exception {
        mockMvc.perform(get("/api/gastos")
                        .header("Authorization", "Bearer " + tokenVendedor()))
                .andExpect(status().isForbidden());
    }

    @Test
    void vendedor_conPRODUCTOS_VER_recibe200() throws Exception {
        mockMvc.perform(get("/api/productos")
                        .header("Authorization", "Bearer " + tokenVendedor()))
                .andExpect(status().isOk());
    }

    @Test
    void admin_accedeATodo() throws Exception {
        mockMvc.perform(get("/api/gastos")
                        .header("Authorization", "Bearer " + tokenAdmin()))
                .andExpect(status().isOk());
    }

    @Test
    void vendedor_sinROLES_EDITAR_recibe403AlCrearRol() throws Exception {
        mockMvc.perform(post("/api/roles")
                        .header("Authorization", "Bearer " + tokenVendedor())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nombre\":\"Rol Prohibido\",\"permisos\":[]}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void vendedor_sinPermisosDeCatalogo_recibe403() throws Exception {
        mockMvc.perform(get("/api/modulos")
                        .header("Authorization", "Bearer " + tokenVendedor()))
                .andExpect(status().isForbidden());
    }

    @Test
    void admin_accedeAlCatalogo() throws Exception {
        mockMvc.perform(get("/api/modulos")
                        .header("Authorization", "Bearer " + tokenAdmin()))
                .andExpect(status().isOk());
    }
}
