package com.ferreplus.security;

import com.ferreplus.entity.Permiso;
import com.ferreplus.entity.Rol;
import com.ferreplus.repository.PermisoRepository;
import com.ferreplus.repository.RolRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.type.filter.AnnotationTypeFilter;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.bind.annotation.RestController;

import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Test de deriva (R9.4): garantiza que el catálogo sembrado y las anotaciones
 * {@code @PreAuthorize} de los controllers no se desalineen.
 *
 * <ul>
 *   <li>Todo código usado en {@code hasAuthority('X')}/{@code hasAnyAuthority(...)}
 *       DEBE existir en el catálogo sembrado (falla si alguien inventa códigos).</li>
 *   <li>Todo permiso del catálogo DEBE estar referenciado por al menos una
 *       anotación, salvo la allowlist documentada:
 *       {@code {VENTAS_EDITAR, ROLES_CREAR, ROLES_ELIMINAR}} (códigos para el
 *       gateo de UI sin endpoint backend correspondiente).</li>
 * </ul>
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
class PreAuthorizeDriftTest {

    private static final Pattern AUTHORITY_PATTERN = Pattern.compile("hasAuthority\\('([A-Z_]+)'\\)");
    private static final Pattern ANY_AUTHORITY_PATTERN = Pattern.compile("hasAnyAuthority\\(([^)]*)\\)");

    private static final Set<String> ALLOWLIST = Set.of("VENTAS_EDITAR", "ROLES_CREAR", "ROLES_ELIMINAR");

    @Autowired
    private PermisoRepository permisoRepository;

    @Autowired
    private RolRepository rolRepository;

    @Test
    void catalogo_seed_es_completo() {
        // 13 módulos, 42 permisos, 69 pares rol_permisos (R1, R6)
        assertEquals(42, permisoRepository.count(),
                "El catálogo debe tener exactamente 42 permisos");

        Set<String> codigos = permisoRepository.findAll().stream()
                .map(Permiso::getCodigo)
                .collect(Collectors.toSet());

        List<Rol> roles = rolRepository.findAllWithPermisos();
        assertEquals(3, roles.size(), "Deben existir los 3 roles base");
        long pares = roles.stream().mapToLong(r -> r.getPermisos().size()).sum();
        assertEquals(69, pares, "ADMIN(42) + VENDEDOR(9) + BODEGUERO(18) = 69 pares");

        for (Rol rol : roles) {
            for (Permiso permiso : rol.getPermisos()) {
                assertTrue(codigos.contains(permiso.getCodigo()),
                        "Permiso del rol sin código en catálogo: " + permiso.getCodigo());
            }
        }
    }

    @Test
    void todo_codigo_en_anotaciones_existe_en_catalogo() {
        Set<String> codigosCatalogo = permisoRepository.findAll().stream()
                .map(Permiso::getCodigo)
                .collect(Collectors.toSet());

        for (String codigo : codigosUsadosEnAnotaciones()) {
            assertTrue(codigosCatalogo.contains(codigo),
                    "Código usado en @PreAuthorize sin respaldo en el catálogo: " + codigo);
        }
    }

    @Test
    void todo_permiso_del_catalogo_esta_protegido_salvo_allowlist() {
        Set<String> codigosCatalogo = permisoRepository.findAll().stream()
                .map(Permiso::getCodigo)
                .collect(Collectors.toSet());
        Set<String> codigosAnotados = codigosUsadosEnAnotaciones();

        Set<String> sinAnotacion = new HashSet<>(codigosCatalogo);
        sinAnotacion.removeAll(codigosAnotados);
        sinAnotacion.removeAll(ALLOWLIST);

        assertTrue(sinAnotacion.isEmpty(),
                "Permisos del catálogo sin @PreAuthorize (fuera de allowlist): " + sinAnotacion);
    }

    private Set<String> codigosUsadosEnAnotaciones() {
        Set<String> codigos = new HashSet<>();

        ClassPathScanningCandidateComponentProvider scanner =
                new ClassPathScanningCandidateComponentProvider(false);
        scanner.addIncludeFilter(new AnnotationTypeFilter(RestController.class));

        for (var beanDefinition : scanner.findCandidateComponents("com.ferreplus.controller")) {
            try {
                Class<?> controller = Class.forName(beanDefinition.getBeanClassName());
                for (Method method : controller.getDeclaredMethods()) {
                    PreAuthorize preAuthorize = method.getAnnotation(PreAuthorize.class);
                    if (preAuthorize == null) {
                        continue;
                    }
                    String expresion = preAuthorize.value();

                    Matcher m = AUTHORITY_PATTERN.matcher(expresion);
                    while (m.find()) {
                        codigos.add(m.group(1));
                    }

                    Matcher any = ANY_AUTHORITY_PATTERN.matcher(expresion);
                    while (any.find()) {
                        String args = any.group(1).replace("'", "").replace(" ", "");
                        for (String arg : args.split(",")) {
                            if (!arg.isBlank()) {
                                codigos.add(arg);
                            }
                        }
                    }
                }
            } catch (ClassNotFoundException e) {
                throw new IllegalStateException("Controller no cargable: " + beanDefinition.getBeanClassName(), e);
            }
        }

        return codigos;
    }
}
