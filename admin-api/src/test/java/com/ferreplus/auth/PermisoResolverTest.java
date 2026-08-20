package com.ferreplus.auth;

import com.ferreplus.entity.Permiso;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.entity.UsuarioPermiso;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.GrantedAuthority;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests de la resolución de autoridades (R9.1, edge cases 10 y 12).
 * Entidades armadas a mano, sin contexto Spring (patrón PrecioServiceTest).
 *
 * Semántica: permisos_efectivos = permisos(rol) ∪ {concedido=true} ∖ {concedido=false}
 * (∖ aplica DESPUÉS de ∪ — el override denegado gana sobre el rol).
 */
@ExtendWith(MockitoExtension.class)
class PermisoResolverTest {

    private final PermisoResolver permisoResolver = new PermisoResolver();

    private Permiso permiso(String codigo) {
        return Permiso.builder().id((long) codigo.hashCode()).codigo(codigo).build();
    }

    private UsuarioPermiso override(Usuario usuario, String codigo, boolean concedido) {
        return UsuarioPermiso.builder()
                .usuario(usuario)
                .permiso(permiso(codigo))
                .concedido(concedido)
                .build();
    }

    private Usuario usuarioConRol(String rolNombre, String... codigosPermiso) {
        Set<Permiso> permisos = java.util.Arrays.stream(codigosPermiso)
                .map(this::permiso)
                .collect(Collectors.toSet());
        Rol rol = Rol.builder().id(1L).nombre(rolNombre).permisos(permisos).build();
        return Usuario.builder().id(1L).rol(rol).build();
    }

    @Test
    void codigosEfectivos_debeAplicarUnionYDenegacion_rolConOverrides() {
        // Given: rol [A,B,C] + overrides concedido=true: [D], concedido=false: [B]
        Usuario usuario = usuarioConRol("VENDEDOR", "A", "B", "C");
        usuario.setOverrides(Set.of(
                override(usuario, "D", true),
                override(usuario, "B", false)
        ));

        // When
        Set<String> resultado = permisoResolver.codigosEfectivos(usuario);

        // Then: exactamente [A,C,D] (R9.1)
        assertEquals(Set.of("A", "C", "D"), resultado);
    }

    @Test
    void codigosEfectivos_denegacionGanaAlRol_edgeCase10() {
        // Given: el rol concede X y el override concedido=false lo quita
        Usuario usuario = usuarioConRol("VENDEDOR", "X");
        usuario.setOverrides(Set.of(override(usuario, "X", false)));

        // When
        Set<String> resultado = permisoResolver.codigosEfectivos(usuario);

        // Then: X NO está (∖ aplica después de ∪)
        assertFalse(resultado.contains("X"), "El override concedido=false debe quitar X del rol");
        assertTrue(resultado.isEmpty());
    }

    @Test
    void codigosEfectivos_rolSinPermisos_edgeCase12() {
        // Given: rol sin permisos (matriz vacía)
        Usuario usuario = usuarioConRol("AUDITOR");

        // When
        Set<String> resultado = permisoResolver.codigosEfectivos(usuario);

        // Then: sin códigos de permiso
        assertTrue(resultado.isEmpty());
    }

    @Test
    void codigosEfectivos_sinOverrides_sonExactamenteLosDelRol() {
        // Given: rol [A,B,C] sin overrides
        Usuario usuario = usuarioConRol("VENDEDOR", "A", "B", "C");

        // When
        Set<String> resultado = permisoResolver.codigosEfectivos(usuario);

        // Then: exactamente los del rol
        assertEquals(Set.of("A", "B", "C"), resultado);
    }

    @Test
    void resolverAutoridades_incluyeCodigosYRoleTransitorio() {
        // Given: usuario VENDEDOR con [A] y override concedido=true [B]
        Usuario usuario = usuarioConRol("VENDEDOR", "A");
        usuario.setOverrides(Set.of(override(usuario, "B", true)));

        // When
        List<GrantedAuthority> autoridades = permisoResolver.resolverAutoridades(usuario);

        // Then: códigos efectivos + ROLE_<nombre> (R5, escenario "Autoridad ROLE_<NOMBRE>")
        Set<String> authorities = autoridades.stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toSet());
        assertEquals(Set.of("A", "B", "ROLE_VENDEDOR"), authorities);
    }

    @Test
    void resolverAutoridades_rolSinPermisos_soloRoleTransitorio() {
        // Given: rol sin permisos
        Usuario usuario = usuarioConRol("AUDITOR");

        // When
        List<GrantedAuthority> autoridades = permisoResolver.resolverAutoridades(usuario);

        // Then: solo ROLE_AUDITOR
        Set<String> authorities = autoridades.stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toSet());
        assertEquals(Set.of("ROLE_AUDITOR"), authorities);
    }
}
