package com.ferreplus.security;

import com.ferreplus.config.DataSeeder;
import com.ferreplus.repository.ModuloRepository;
import com.ferreplus.repository.PermisoRepository;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * El seeder DEBE ser idempotente (R1): ejecutarlo dos veces sobre el mismo
 * estado no debe crear duplicados ni alterar matrices.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
class DataSeederIdempotencyTest {

    @Autowired
    private DataSeeder dataSeeder;

    @Autowired
    private ModuloRepository moduloRepository;

    @Autowired
    private PermisoRepository permisoRepository;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Test
    void dobleEjecucion_noCambiaElEstado() {
        long modulos = moduloRepository.count();
        long permisos = permisoRepository.count();
        long pares = rolRepository.findAllWithPermisos().stream()
                .mapToLong(r -> r.getPermisos().size()).sum();
        long usuarios = usuarioRepository.count();

        dataSeeder.run();

        assertEquals(modulos, moduloRepository.count(), "Los módulos no deben duplicarse");
        assertEquals(permisos, permisoRepository.count(), "Los permisos no deben duplicarse");
        assertEquals(pares, rolRepository.findAllWithPermisos().stream()
                .mapToLong(r -> r.getPermisos().size()).sum(), "Las matrices de rol no deben duplicarse");
        assertEquals(usuarios, usuarioRepository.count(), "El usuario admin no debe duplicarse");
    }

    @Test
    void seed_siembraElEstadoCompletoEsperado() {
        assertEquals(15, moduloRepository.count(), "Deben sembrarse 15 módulos");
        assertEquals(45, permisoRepository.count(), "Deben sembrarse 45 permisos");

        var roles = rolRepository.findAllWithPermisos();
        assertEquals(3, roles.size(), "Deben existir exactamente 3 roles base");

        assertEquals(72, roles.stream().mapToLong(r -> r.getPermisos().size()).sum(),
                "ADMIN(45) + VENDEDOR(9) + BODEGUERO(18) = 72 pares rol_permisos");

        assertTrue(rolRepository.findByNombre("CAJERO").isEmpty(),
                "El rol CAJERO fue eliminado del modelo (R7 REMOVED)");
        assertTrue(rolRepository.findByNombre("SUPERVISOR").isEmpty(),
                "El rol SUPERVISOR fue eliminado del modelo (R7 REMOVED)");

        assertTrue(usuarioRepository.findByEmail("admin@ferreplus.com").isPresent(),
                "El usuario admin debe existir tras el seed");
    }
}
