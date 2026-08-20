package com.ferreplus.security;

import com.ferreplus.dto.AuthLoginDTO;
import com.ferreplus.dto.AuthResponseDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.repository.AuditoriaRepository;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.service.AuthService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * R2/R3/R9 — Consulta paginada/filtrada (LOGS_VER) y borrado por rango
 * (LOGS_ELIMINAR) de /api/logs con tokens JWT reales y H2.
 *
 * <p>Patrón {@link SecurityEnforcementIntegrationTest}: se crean usuarios reales,
 * se loguean por {@link AuthService} y se ejercitan endpoints con el token.
 * Las filas de {@code auditoria} se siembran directamente por repositorio con
 * fechas controladas para probar filtros y rangos de borrado de forma determinista.</p>
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class LogControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private AuditoriaRepository auditoriaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private Usuario admin;
    private Usuario vendedor;
    private String tokenAdmin;
    private String tokenVendedor;

    @BeforeEach
    void setUp() {
        admin = usuarioRepository.findByEmail("admin@ferreplus.com").orElseThrow();
        tokenAdmin = login("admin@ferreplus.com", "admin123");

        Rol rolVendedor = rolRepository.findByNombre("VENDEDOR").orElseThrow();
        vendedor = usuarioRepository.save(Usuario.builder()
                .nombre("Vendedor Logs")
                .email("vendedor-logs@ferreplus.com")
                .password(passwordEncoder.encode("password123"))
                .rol(rolVendedor)
                .activo(true)
                .build());
        tokenVendedor = login("vendedor-logs@ferreplus.com", "password123");
    }

    @AfterEach
    void clearContext() {
        org.springframework.security.core.context.SecurityContextHolder.clearContext();
    }

    private String login(String email, String password) {
        AuthLoginDTO dto = new AuthLoginDTO();
        dto.setEmail(email);
        dto.setPassword(password);
        AuthResponseDTO response = authService.login(dto);
        return response.getToken();
    }

    public Long sembrar(String entidad, Long entidadId, String accion, LocalDateTime fecha, Usuario actor) {
        // INSERT nativo vía JdbcTemplate: controlamos la fecha y la fila NO queda en
        // el persistence context de JPA (evita que la caché de 1er nivel devuelva
        // fecha=now() al compilar el filtro/borrado).
        org.springframework.jdbc.support.GeneratedKeyHolder kh =
                new org.springframework.jdbc.support.GeneratedKeyHolder();
        jdbcTemplate.update(con -> {
            var ps = con.prepareStatement(
                    "INSERT INTO auditoria (entidad, entidad_id, accion, usuario_id, detalle, fecha) VALUES (?, ?, ?, ?, ?, ?)",
                    new String[]{"id"});
            ps.setString(1, entidad);
            ps.setLong(2, entidadId);
            ps.setString(3, accion);
            ps.setObject(4, actor != null ? actor.getId() : null);
            ps.setString(5, "{\"prueba\":true}");
            ps.setTimestamp(6, java.sql.Timestamp.valueOf(fecha));
            return ps;
        }, kh);
        return kh.getKey().longValue();
    }

    private LocalDateTime dia(int day) {
        return LocalDateTime.of(2026, 1, day, 10, 0);
    }

    // ---- R2: consulta paginada/filtrada ----

    @Test
    void admin_consultaLogs_devuelvePageConEstructuraCompleta() throws Exception {
        sembrar("PRODUCTO", 1L, "CREAR", dia(1), admin);

        mockMvc.perform(get("/api/logs?page=0&size=20")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.totalElements").value(org.hamcrest.Matchers.greaterThan(0)))
                .andExpect(jsonPath("$.totalPages").isNumber())
                .andExpect(jsonPath("$.content[0].entidad").exists())
                .andExpect(jsonPath("$.content[0].entidadId").exists())
                .andExpect(jsonPath("$.content[0].accion").exists())
                .andExpect(jsonPath("$.content[0].fecha").exists());
    }

    @Test
    void vendedor_sinLOGS_VER_recibe403() throws Exception {
        mockMvc.perform(get("/api/logs")
                        .header("Authorization", "Bearer " + tokenVendedor))
                .andExpect(status().isForbidden());
    }

    @Test
    void filtroPorRangoDevuelveSoloFilasDelRango() throws Exception {
        sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);
        sembrar("VENTA", 2L, "CREAR", dia(15), admin);
        sembrar("VENTA", 3L, "CREAR", dia(25), admin);

        mockMvc.perform(get("/api/logs?fechaDesde=2026-01-10&fechaHasta=2026-01-20")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].entidad").value("VENTA"))
                .andExpect(jsonPath("$.content[0].accion").value("CREAR"));
    }

    @Test
    void filtroCombinadoEntidadYAccion() throws Exception {
        sembrar("VENTA", 2L, "CREAR", dia(15), admin);
        sembrar("VENTA", 3L, "ANULAR", dia(20), admin);
        sembrar("PRODUCTO", 1L, "CREAR", dia(22), admin);

        mockMvc.perform(get("/api/logs?entidad=VENTA&accion=CREAR")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].entidad").value("VENTA"))
                .andExpect(jsonPath("$.content[0].accion").value("CREAR"));
    }

    @Test
    void filtroPorUnSoloExtremo_Desde_soloDevuelvePosteriores() throws Exception {
        sembrar("VENTA", 1L, "CREAR", dia(5), admin);
        sembrar("VENTA", 2L, "CREAR", dia(15), admin);

        mockMvc.perform(get("/api/logs?fechaDesde=2026-01-10&entidad=VENTA")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].entidadId").value(2));
    }

    @Test
    void filtroPorUsuarioId_devuelveSoloEseUsuario() throws Exception {
        sembrar("VENTA", 1L, "CREAR", dia(5), admin);
        sembrar("VENTA", 2L, "CREAR", dia(15), vendedor);

        mockMvc.perform(get("/api/logs?usuarioId=" + vendedor.getId() + "&entidad=VENTA")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].usuarioId").value(vendedor.getId()));
    }

    @Test
    void filtroPorUsuarioNombre_devuelveSoloEseUsuario() throws Exception {
        sembrar("VENTA", 1L, "CREAR", dia(5), admin);
        sembrar("VENTA", 2L, "CREAR", dia(15), vendedor);

        mockMvc.perform(get("/api/logs?usuarioNombre=" + vendedor.getNombre() + "&entidad=VENTA")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].usuarioId").value(vendedor.getId()));
    }

    @Test
    void filtroPorUsuarioNombre_caseInsensitiveYContiene() throws Exception {
        sembrar("VENTA", 1L, "CREAR", dia(5), vendedor);

        // Nombre real: "Vendedor Logs" — búsqueda CONTAINS con mayúsculas/parcial
        mockMvc.perform(get("/api/logs?usuarioNombre=VENDEDOR&entidad=VENTA")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void filtroPorUsuarioNombre_vacioONull_ignorado() throws Exception {
        sembrar("VENTA", 1L, "CREAR", dia(5), admin);
        sembrar("VENTA", 2L, "CREAR", dia(15), vendedor);

        // usuarioNombre vacío → no filtra (se ignora)
        mockMvc.perform(get("/api/logs?usuarioNombre=&entidad=VENTA")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2));

        // Sin usuarioNombre → no filtra
        mockMvc.perform(get("/api/logs?entidad=VENTA")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2));
    }

    // ---- R3: borrado por rango ----

    @Test
    void vendedor_sinLOGS_ELIMINAR_recibe403SinBorrarFilas() throws Exception {
        Long fila = sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);
        long antes = auditoriaRepository.count();

        mockMvc.perform(delete("/api/logs?desde=2026-01-01&hasta=2026-01-31")
                        .header("Authorization", "Bearer " + tokenVendedor))
                .andExpect(status().isForbidden());

        assertEquals(antes, auditoriaRepository.count());
        assertTrue(auditoriaRepository.findById(fila).isPresent(),
                "El 403 no debe borrar filas");
    }

    @Test
    void borradoSinParametros_recibe400YNoBorra() throws Exception {
        sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);
        long antes = auditoriaRepository.count();

        mockMvc.perform(delete("/api/logs?desde=2026-01-01")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isBadRequest());

        mockMvc.perform(delete("/api/logs")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isBadRequest());

        assertEquals(antes, auditoriaRepository.count(), "El 400 no debe borrar filas");
    }

    @Test
    void rangoRevertido_recibe400YNoBorra() throws Exception {
        sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);
        long antes = auditoriaRepository.count();

        mockMvc.perform(delete("/api/logs?desde=2026-01-31&hasta=2026-01-01")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isBadRequest());

        assertEquals(antes, auditoriaRepository.count(), "El rango revertido no debe borrar filas");
    }

    @Test
    void formatoInvalido_recibe400YNoBorra() throws Exception {
        sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);
        long antes = auditoriaRepository.count();

        mockMvc.perform(delete("/api/logs?desde=abc&hasta=xyz")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isBadRequest());

        assertEquals(antes, auditoriaRepository.count(), "El formato inválido no debe borrar filas");
    }

    @Test
    void borradoPorRango_devuelveConteoYQuitaFilasFisicamente() throws Exception {
        Long f1 = sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);
        Long f2 = sembrar("VENTA", 2L, "CREAR", dia(15), admin);
        sembrar("VENTA", 3L, "ANULAR", dia(25), admin);

        mockMvc.perform(delete("/api/logs?desde=2026-01-01&hasta=2026-01-31")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.eliminados").value(3));

        assertFalse(auditoriaRepository.findById(f1).isPresent(),
                "Las filas deben borrarse físicamente de auditoria");
        assertFalse(auditoriaRepository.findById(f2).isPresent());
    }

    @Test
    void rangoSinRegistros_devuelve200Eliminados0() throws Exception {
        Long fueraDeRango = sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);

        mockMvc.perform(delete("/api/logs?desde=2025-01-01&hasta=2025-01-31")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.eliminados").value(0));

        assertTrue(auditoriaRepository.findById(fueraDeRango).isPresent(),
                "El rango vacío no debe tocar filas fuera del rango");
    }

    @Test
    void borradoPorRango_noSeAutoAudita() throws Exception {
        sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);
        long authAntes = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("AUTH", admin.getId(), "LOGIN").size();

        mockMvc.perform(delete("/api/logs?desde=2026-01-01&hasta=2026-01-31")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk());

        var logsEliminar = auditoriaRepository.findByEntidadAndEntidadIdAndAccion("LOGS", null, "ELIMINAR");
        assertTrue(logsEliminar.isEmpty(), "El borrado de logs NO debe generar su propia fila (D6)");

        long authDespues = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("AUTH", admin.getId(), "LOGIN").size();
        assertEquals(authAntes, authDespues, "El borrado no debe generar filas AUTH/LOGIN");
    }

    @Test
    void noExisteBorradoPorFilaIndividual() throws Exception {
        Long fila = sembrar("PRODUCTO", 1L, "CREAR", dia(5), admin);

        mockMvc.perform(delete("/api/logs/" + fila)
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isNotFound());

        assertTrue(auditoriaRepository.findById(fila).isPresent(),
                "No debe existir DELETE /api/logs/{id}");
    }

    // ===== GET /api/logs/usuarios (R7 refinamiento — selector del filtro) =====

    @Test
    void usuariosConActividad_devuelveSoloConActividad() throws Exception {
        // Admin ya tiene filas de auditoría (login). El endpoint debe devolver un array no vacío
        // con al menos el admin (puede haber más usuarios del seed o tests previos en H2).
        mockMvc.perform(get("/api/logs/usuarios")
                        .header("Authorization", "Bearer " + tokenAdmin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$[0].id").isNumber())
                .andExpect(jsonPath("$[0].nombre").isString());
    }

    @Test
    void usuariosConActividad_sinLOGS_VER_recibe403() throws Exception {
        // El vendedor setUp() tiene solo permisos VENDEDOR, no LOGS_VER
        mockMvc.perform(get("/api/logs/usuarios")
                        .header("Authorization", "Bearer " + tokenVendedor))
                .andExpect(status().isForbidden());
    }
}
