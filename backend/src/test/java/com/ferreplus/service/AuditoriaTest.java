package com.ferreplus.service;

import com.ferreplus.dto.RolRequestDTO;
import com.ferreplus.dto.UsuarioRequestDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.exception.ConflictException;
import com.ferreplus.repository.AuditoriaRepository;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * R10 — Auditoría atómica: la fila de auditoría se persiste en la misma
 * transacción que la operación; una operación rechazada (409) NO deja fila.
 * El principal autenticado (admin) queda registrado como usuario_id.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
@Transactional
class AuditoriaTest {

    @Autowired
    private UsuarioService usuarioService;

    @Autowired
    private RolService rolService;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private AuditoriaRepository auditoriaRepository;

    private Usuario admin;

    @BeforeEach
    void autenticarAdmin() {
        admin = usuarioRepository.findByEmail("admin@ferreplus.com").orElseThrow();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(admin, null, List.of()));
    }

    @AfterEach
    void limpiarContexto() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void crearUsuario_registraFilaDeAuditoriaConElActor() {
        Rol vendedor = rolRepository.findByNombre("VENDEDOR").orElseThrow();

        UsuarioRequestDTO dto = new UsuarioRequestDTO();
        dto.setNombre("Auditoría Test");
        dto.setEmail("auditoria@ferreplus.com");
        dto.setPassword("password123");
        dto.setRolId(vendedor.getId());

        var creado = usuarioService.create(dto);

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("USUARIO", creado.getId(), "CREAR");
        assertEquals(1, filas.size(), "Crear usuario debe generar exactamente 1 fila USUARIO/CREAR");
        assertEquals(creado.getId(), filas.get(0).getEntidadId());
        assertEquals(admin.getId(), filas.get(0).getUsuario().getId(),
                "El usuario_id de la auditoría debe ser el actor autenticado");
    }

    @Test
    void eliminarRolEnUso_lanza409SinFilaDeAuditoria() {
        // El rol ADMIN del seed tiene al menos el usuario admin activo → en uso
        Rol adminRol = rolRepository.findByNombre("ADMIN").orElseThrow();

        assertThrows(ConflictException.class, () -> rolService.delete(adminRol.getId()));

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("ROL", adminRol.getId(), "ELIMINAR");
        assertTrue(filas.isEmpty(), "Un 409 no debe dejar fila de auditoría ROL/ELIMINAR");
    }

    @Test
    void crearRol_registraFilaDeAuditoria() {
        var dto = new RolRequestDTO();
        dto.setNombre("AUDITORIA_ROL");
        dto.setPermisos(List.of("VENTAS_VER"));

        var creado = rolService.create(dto);

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("ROL", creado.getId(), "CREAR");
        assertEquals(1, filas.size(), "Crear rol debe generar exactamente 1 fila ROL/CREAR");
        assertNotNull(filas.get(0).getDetalle(), "El detalle debe serializar la matriz en JSON");
    }

    @Test
    void editarMatrizDeRol_registraFilaDeAuditoria() {
        Rol vendedor = rolRepository.findByNombre("VENDEDOR").orElseThrow();

        var dto = new RolRequestDTO();
        dto.setNombre(vendedor.getNombre());
        dto.setPermisos(List.of("VENTAS_VER", "PRECIOS_VER"));

        rolService.update(vendedor.getId(), dto);

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("ROL", vendedor.getId(), "ACTUALIZAR");
        assertEquals(1, filas.size(), "Editar la matriz debe generar exactamente 1 fila ROL/ACTUALIZAR");
        assertNotNull(filas.get(0).getDetalle(), "El detalle debe reflejar la nueva matriz");
    }

    @Test
    void operacionFallida_noDejaFilaDeAuditoria() {
        // Nombre duplicado → 400 antes de auditar; no debe quedar fila ROL/CREAR
        var dto = new RolRequestDTO();
        dto.setNombre("ADMIN");
        dto.setPermisos(List.of("VENTAS_VER"));

        assertThrows(com.ferreplus.exception.BadRequestException.class,
                () -> rolService.create(dto));

        List<Auditoria> filas = auditoriaRepository
                .findByEntidadAndEntidadIdAndAccion("ROL", null, "CREAR");
        assertTrue(filas.isEmpty(), "Una operación rechazada no debe dejar fila de auditoría");
    }
}
