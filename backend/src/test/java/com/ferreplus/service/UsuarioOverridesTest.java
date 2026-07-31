package com.ferreplus.service;

import com.ferreplus.auth.PermisoResolver;
import com.ferreplus.dto.UsuarioDTO;
import com.ferreplus.dto.UsuarioPermisoRequestDTO;
import com.ferreplus.dto.UsuarioRequestDTO;
import com.ferreplus.entity.Permiso;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.repository.PermisoRepository;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

/**
 * R4 — Overrides de permisos por usuario: concedido=true agrega sobre el rol,
 * concedido=false quita, y la lista vacía en PUT elimina todos los overrides.
 * Cada test transacciona y revierte, preservando el seed del catálogo.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@Transactional
class UsuarioOverridesTest {

    @Autowired
    private UsuarioService usuarioService;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private PermisoRepository permisoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private PermisoResolver permisoResolver;

    private Permiso ventasVer;
    private Permiso gastosVer;
    private Rol rolBase;

    @BeforeEach
    void setUp() {
        ventasVer = permisoRepository.findByCodigo("VENTAS_VER").orElseThrow();
        gastosVer = permisoRepository.findByCodigo("GASTOS_VER").orElseThrow();

        rolBase = rolRepository.save(Rol.builder()
                .nombre("CONTADOR_TEST")
                .descripcion("Rol de prueba")
                .permisos(new HashSet<>(Set.of(ventasVer, gastosVer)))
                .build());
    }

    @Test
    void overrideConcedidoTrue_agregaPermisoSobreElRol() {
        UsuarioRequestDTO dto = requestBase("override-grant@ferreplus.com", rolBase.getId());
        dto.getOverrides().add(override("PRECIOS_VER", true));

        UsuarioDTO creado = usuarioService.create(dto);

        assertTrue(creado.getPermisos().contains("VENTAS_VER"));
        assertTrue(creado.getPermisos().contains("GASTOS_VER"));
        assertTrue(creado.getPermisos().contains("PRECIOS_VER"),
                "El permiso concedido por override debe sumarse a los del rol");
    }

    @Test
    void overrideConcedidoFalse_quitaPermisoDelRol() {
        UsuarioRequestDTO dto = requestBase("override-deny@ferreplus.com", rolBase.getId());
        dto.getOverrides().add(override("GASTOS_VER", false));

        UsuarioDTO creado = usuarioService.create(dto);

        assertTrue(creado.getPermisos().contains("VENTAS_VER"));
        assertFalse(creado.getPermisos().contains("GASTOS_VER"),
                "El permiso denegado por override debe restarse de los del rol");
    }

    @Test
    void updateConOverridesVacios_eliminaTodosLosOverrides() {
        UsuarioDTO creado = usuarioService.create(requestBase("override-remove@ferreplus.com", rolBase.getId()));
        UsuarioDTO conOverride = usuarioService.update(creado.getId(), conOverrideDto(
                "override-remove@ferreplus.com", rolBase.getId(), "PRECIOS_VER", true));

        assertTrue(conOverride.getPermisos().contains("PRECIOS_VER"));

        UsuarioDTO sinOverrides = usuarioService.update(creado.getId(),
                requestBase("override-remove@ferreplus.com", rolBase.getId()));

        assertFalse(sinOverrides.getPermisos().contains("PRECIOS_VER"),
                "Con overrides vacíos el permiso agregado debe desaparecer");
        assertEquals(0, sinOverrides.getOverrides().size());
    }

    @Test
    void overrideConCodigoInexistente_lanza400() {
        UsuarioRequestDTO dto = requestBase("override-invalido@ferreplus.com", rolBase.getId());
        dto.getOverrides().add(override("INVENTADO_VER", true));

        assertThrows(BadRequestException.class, () -> usuarioService.create(dto));
    }

    @Test
    void overrideDuplicado_lanza400() {
        UsuarioRequestDTO dto = requestBase("override-dup@ferreplus.com", rolBase.getId());
        dto.getOverrides().add(override("GASTOS_VER", true));
        dto.getOverrides().add(override("GASTOS_VER", false));

        assertThrows(BadRequestException.class, () -> usuarioService.create(dto),
                "Concedido=true y false para el mismo permiso es un duplicado → 400");
    }

    @Test
    void permisosEfectivosResueltos_porElResolver_coincidenConElDTO() {
        UsuarioRequestDTO dto = requestBase("override-resolver@ferreplus.com", rolBase.getId());
        dto.getOverrides().add(override("GASTOS_VER", false));

        UsuarioDTO creado = usuarioService.create(dto);
        Usuario persistido = usuarioRepository.findWithPermisosById(creado.getId()).orElseThrow();

        assertEquals(creado.getPermisos(),
                permisoResolver.codigosEfectivos(persistido).stream().sorted().toList());
    }

    @Test
    void usuarioDTO_exponeRolBaseYPermisosYOverrides() {
        UsuarioRequestDTO dto = requestBase("dto-contract@ferreplus.com", rolBase.getId());
        dto.getOverrides().add(override("GASTOS_VER", false));

        UsuarioDTO creado = usuarioService.create(dto);

        assertEquals(rolBase.getId(), creado.getRolId(), "El DTO debe exponer rolId raíz");
        assertEquals("CONTADOR_TEST", creado.getRolNombre(), "El DTO debe exponer rolNombre raíz");
        assertTrue(creado.getPermisos().contains("VENTAS_VER"));
        assertFalse(creado.getPermisos().contains("GASTOS_VER"));
        assertEquals(1, creado.getOverrides().size());
        assertEquals("GASTOS_VER", creado.getOverrides().get(0).getPermisoCodigo());
        assertFalse(creado.getOverrides().get(0).isConcedido());
    }

    private UsuarioRequestDTO requestBase(String email, Long rolId) {
        UsuarioRequestDTO dto = new UsuarioRequestDTO();
        dto.setNombre("Usuario Override");
        dto.setEmail(email);
        dto.setPassword("password123");
        dto.setRolId(rolId);
        return dto;
    }

    private UsuarioPermisoRequestDTO override(String codigo, boolean concedido) {
        UsuarioPermisoRequestDTO o = new UsuarioPermisoRequestDTO();
        o.setPermisoCodigo(codigo);
        o.setConcedido(concedido);
        return o;
    }

    private UsuarioRequestDTO conOverrideDto(String email, Long rolId, String codigo, boolean concedido) {
        UsuarioRequestDTO dto = requestBase(email, rolId);
        dto.getOverrides().add(override(codigo, concedido));
        return dto;
    }
}
