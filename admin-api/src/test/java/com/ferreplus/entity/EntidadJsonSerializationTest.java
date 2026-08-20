package com.ferreplus.entity;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Regression test (bugfix de serialización JSON): los ciclos bidireccionales
 * introducidos por STACK 1 (Modulo↔Permiso, Rol→Permiso→Modulo y
 * Usuario↔UsuarioPermiso) NO deben causar recursión infinita
 * ({@link StackOverflowError}) al serializar entidades con campo {@code usuario}
 * (Gasto, Venta, Compra, MovimientoStock, ...).
 *
 * <p>Se construye el grafo circular en memoria (builders de Lombok) tal como lo
 * armaría la BD con sus back-references, y se verifica que
 * {@link ObjectMapper#writeValueAsString(Object)} complete sin excepción.
 * Las anotaciones {@code @JsonIgnoreProperties} son de Jackson puro: no se
 * necesita contexto Spring (patrón de {@code PermisoResolverTest}).
 */
class EntidadJsonSerializationTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Construye el grafo circular completo: un Modulo con un Permiso cuyo
     * {@code modulo} apunta de vuelta al mismo Modulo; un Rol que contiene ese
     * Permiso; un Usuario con ese rol y un override (UsuarioPermiso) con
     * back-references a usuario y permiso.
     */
    private Gasto gastoConGrafoCircular() {
        Modulo modulo = Modulo.builder()
                .id(1L)
                .nombre("Ventas")
                .codigo("VENTAS")
                .orden(1)
                .build();

        Permiso permiso = Permiso.builder()
                .id(1L)
                .codigo("VENTAS_VER")
                .nombre("Ver ventas")
                .accion("VER")
                .modulo(modulo)              // Permiso → Modulo
                .build();
        modulo.getPermisos().add(permiso);   // Modulo → Permiso (back-reference)

        Rol rol = Rol.builder()
                .id(1L)
                .nombre("VENDEDOR")
                .descripcion("Rol de prueba")
                .permisos(Set.of(permiso))   // Rol → Permiso → Modulo
                .build();

        Usuario usuario = Usuario.builder()
                .id(1L)
                .nombre("Usuario Prueba")
                .email("prueba@ferreplus.com")
                .password("password123")
                .activo(true)
                .rol(rol)                    // Usuario → Rol → Permiso → Modulo
                .build();

        UsuarioPermiso override = UsuarioPermiso.builder()
                .usuario(usuario)            // UsuarioPermiso → Usuario (back-ref)
                .permiso(permiso)            // UsuarioPermiso → Permiso
                .concedido(true)
                .build();
        usuario.getOverrides().add(override); // Usuario → UsuarioPermiso (back-ref)

        return Gasto.builder()
                .id(1L)
                .descripcion("Servicio de luz")
                .monto(new BigDecimal("120.50"))
                .usuario(usuario)            // Gasto → Usuario → grafo completo
                .build();
    }

    @Test
    void serializarGasto_conGrafoCircularCompleto_noLanzaRecursionInfinita() throws Exception {
        Gasto gasto = gastoConGrafoCircular();

        // Antes del fix: StackOverflowError por el ciclo
        // usuario → rol → permisos → permiso.modulo → modulo.permisos → ...
        String json = objectMapper.writeValueAsString(gasto);

        assertNotNull(json, "La serialización debe completar sin excepción");
        assertFalse(json.isBlank(), "El JSON no debe ser vacío");
        assertTrue(json.contains("VENTAS_VER"), "El JSON debe incluir el permiso del rol");
        assertTrue(json.contains("Usuario Prueba"), "El JSON debe incluir el usuario");
    }

    @Test
    void serializarUsuario_conOverrides_noLanzaRecursionInfinita() throws Exception {
        Gasto gasto = gastoConGrafoCircular();
        Usuario usuario = gasto.getUsuario();

        // Cubre el camino usuario → overrides → usuario (rol/overrides ignorados
        // en el back-reference de UsuarioPermiso.usuario) y rol → permisos.
        String json = objectMapper.writeValueAsString(usuario);

        assertNotNull(json, "La serialización debe completar sin excepción");
        assertFalse(json.isBlank(), "El JSON no debe ser vacío");
        assertTrue(json.contains("VENDEDOR"), "El JSON debe incluir el rol");
    }
}
