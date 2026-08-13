package com.ferreplus.config;

import com.ferreplus.entity.Modulo;
import com.ferreplus.entity.GuiaSistema;
import com.ferreplus.entity.Permiso;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.repository.ModuloRepository;
import com.ferreplus.repository.PermisoRepository;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.repository.GuiaSistemaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Siembra el catálogo de módulos/permisos, la matriz de los roles base y el
 * usuario administrador (R1, R3, R6). Reemplaza a schema.sql/data.sql, que NO
 * se ejecutan ({@code spring.sql.init.mode=never}).
 *
 * <p>IDEMPOTENTE por entidad: módulos y permisos se crean solo si el código no
 * existe; a los roles existentes se les AÑADE la matriz faltante (nunca se
 * quitan permisos que el admin haya ajustado desde la UI); el usuario admin se
 * crea solo si el email no existe. Segunda ejecución → sin cambios.</p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final ModuloRepository moduloRepository;
    private final PermisoRepository permisoRepository;
    private final RolRepository rolRepository;
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final GuiaSistemaRepository guiaSistemaRepository;

    /** Módulo → (orden, acciones que aplican). El orden define el sidebar. */
    private static final Map<String, int[]> MODULOS = new LinkedHashMap<>();
    private static final Map<String, String> NOMBRES_MODULO = new HashMap<>();

    static {
        MODULOS.put("DASHBOARD", new int[]{1, 1, 0, 0, 0});
        MODULOS.put("PRODUCTOS", new int[]{2, 1, 1, 1, 1});
        MODULOS.put("CATEGORIAS", new int[]{3, 1, 1, 1, 1});
        MODULOS.put("PROVEEDORES", new int[]{4, 1, 1, 1, 1});
        MODULOS.put("CLIENTES", new int[]{5, 1, 1, 1, 1});
        MODULOS.put("VENTAS", new int[]{6, 1, 1, 1, 1});
        MODULOS.put("COMPRAS", new int[]{7, 1, 1, 1, 1});
        MODULOS.put("PRECIOS", new int[]{8, 1, 0, 1, 0});
        MODULOS.put("MOVIMIENTOS", new int[]{9, 1, 1, 0, 0});
        MODULOS.put("GASTOS", new int[]{10, 1, 1, 1, 1});
        MODULOS.put("USUARIOS", new int[]{11, 1, 1, 1, 1});
        MODULOS.put("ROLES", new int[]{12, 1, 1, 1, 1});
        MODULOS.put("REPORTES", new int[]{13, 1, 0, 0, 0});
        MODULOS.put("LOGS", new int[]{14, 1, 0, 0, 1});

        NOMBRES_MODULO.put("DASHBOARD", "Dashboard");
        NOMBRES_MODULO.put("PRODUCTOS", "Productos");
        NOMBRES_MODULO.put("CATEGORIAS", "Categorías");
        NOMBRES_MODULO.put("PROVEEDORES", "Proveedores");
        NOMBRES_MODULO.put("CLIENTES", "Clientes");
        NOMBRES_MODULO.put("VENTAS", "Ventas");
        NOMBRES_MODULO.put("COMPRAS", "Compras");
        NOMBRES_MODULO.put("PRECIOS", "Precios");
        NOMBRES_MODULO.put("MOVIMIENTOS", "Movimientos");
        NOMBRES_MODULO.put("GASTOS", "Gastos");
        NOMBRES_MODULO.put("USUARIOS", "Usuarios");
        NOMBRES_MODULO.put("ROLES", "Roles");
        NOMBRES_MODULO.put("REPORTES", "Reportes");
        NOMBRES_MODULO.put("LOGS", "Logs");
    }

    private static final String[] ACCIONES = {"VER", "CREAR", "EDITAR", "ELIMINAR"};
    private static final Map<String, String> VERBO_ACCION = new HashMap<>();

    static {
        VERBO_ACCION.put("VER", "Ver");
        VERBO_ACCION.put("CREAR", "Crear");
        VERBO_ACCION.put("EDITAR", "Editar");
        VERBO_ACCION.put("ELIMINAR", "Eliminar");
    }

    private static final Map<String, Set<String>> MATRIZ_ROLES = new LinkedHashMap<>();

    static {
        MATRIZ_ROLES.put("ADMIN", Set.of(
                "DASHBOARD_VER",
                "CHAT_INDEX_REBUILD",
                "PRODUCTOS_VER", "PRODUCTOS_CREAR", "PRODUCTOS_EDITAR", "PRODUCTOS_ELIMINAR",
                "CATEGORIAS_VER", "CATEGORIAS_CREAR", "CATEGORIAS_EDITAR", "CATEGORIAS_ELIMINAR",
                "PROVEEDORES_VER", "PROVEEDORES_CREAR", "PROVEEDORES_EDITAR", "PROVEEDORES_ELIMINAR",
                "CLIENTES_VER", "CLIENTES_CREAR", "CLIENTES_EDITAR", "CLIENTES_ELIMINAR",
                "VENTAS_VER", "VENTAS_CREAR", "VENTAS_EDITAR", "VENTAS_ELIMINAR",
                "COMPRAS_VER", "COMPRAS_CREAR", "COMPRAS_EDITAR", "COMPRAS_ELIMINAR",
                "PRECIOS_VER", "PRECIOS_EDITAR",
                "MOVIMIENTOS_VER", "MOVIMIENTOS_CREAR",
                "GASTOS_VER", "GASTOS_CREAR", "GASTOS_EDITAR", "GASTOS_ELIMINAR",
                "USUARIOS_VER", "USUARIOS_CREAR", "USUARIOS_EDITAR", "USUARIOS_ELIMINAR",
                "ROLES_VER", "ROLES_CREAR", "ROLES_EDITAR", "ROLES_ELIMINAR",
                "REPORTES_VER",
                "LOGS_VER", "LOGS_ELIMINAR"
        ));
        MATRIZ_ROLES.put("VENDEDOR", Set.of(
                "DASHBOARD_VER",
                "PRODUCTOS_VER",
                "CLIENTES_VER", "CLIENTES_CREAR", "CLIENTES_EDITAR",
                "VENTAS_VER", "VENTAS_CREAR",
                "PRECIOS_VER",
                "REPORTES_VER"
        ));
        MATRIZ_ROLES.put("BODEGUERO", Set.of(
                "DASHBOARD_VER",
                "PRODUCTOS_VER", "PRODUCTOS_CREAR", "PRODUCTOS_EDITAR",
                "CATEGORIAS_VER", "CATEGORIAS_CREAR", "CATEGORIAS_EDITAR",
                "PROVEEDORES_VER", "PROVEEDORES_CREAR", "PROVEEDORES_EDITAR",
                "CLIENTES_VER",
                "VENTAS_VER",
                "COMPRAS_VER", "COMPRAS_CREAR", "COMPRAS_EDITAR",
                "PRECIOS_VER",
                "MOVIMIENTOS_VER", "MOVIMIENTOS_CREAR"
        ));
    }

    private static final String ADMIN_EMAIL = "admin@ferreplus.com";
    private static final String ADMIN_PASSWORD = "admin123";

    @Override
    @Transactional
    public void run(String... args) {
        Map<String, Permiso> permisos = sembrarCatalogo();
        sembrarRoles(permisos);
        sembrarUsuarioAdmin();
        sembrarGuiasSistema();
        log.info("Seeder de catálogo completado: {} módulos, {} permisos, {} pares rol_permisos, usuario admin verificado",
                moduloRepository.count(),
                permisoRepository.count(),
                rolRepository.findAllWithPermisos().stream().mapToLong(r -> r.getPermisos().size()).sum());
    }

    private Map<String, Permiso> sembrarCatalogo() {
        Map<String, Permiso> porCodigo = new HashMap<>();

        for (Map.Entry<String, int[]> entry : MODULOS.entrySet()) {
            String codigoModulo = entry.getKey();
            int[] config = entry.getValue();
            int orden = config[0];

            Modulo modulo = moduloRepository.findByCodigo(codigoModulo).orElseGet(() -> {
                Modulo nuevo = Modulo.builder()
                        .nombre(NOMBRES_MODULO.get(codigoModulo))
                        .codigo(codigoModulo)
                        .orden(orden)
                        .build();
                return moduloRepository.save(nuevo);
            });

            for (int i = 0; i < ACCIONES.length; i++) {
                if (config[i + 1] != 1) {
                    continue;
                }
                String accion = ACCIONES[i];
                String codigoPermiso = codigoModulo + "_" + accion;
                Permiso permiso = permisoRepository.findByCodigo(codigoPermiso).orElseGet(() -> {
                    Permiso nuevo = Permiso.builder()
                            .codigo(codigoPermiso)
                            .nombre(VERBO_ACCION.get(accion) + " " + NOMBRES_MODULO.get(codigoModulo).toLowerCase())
                            .accion(accion)
                            .modulo(modulo)
                            .build();
                    return permisoRepository.save(nuevo);
                });
                porCodigo.put(codigoPermiso, permiso);
            }
        }

        log.info("Catálogo: {} módulos, {} permisos", moduloRepository.count(), permisoRepository.count());
        return porCodigo;
    }

    private void sembrarRoles(Map<String, Permiso> permisosPorCodigo) {
        for (Map.Entry<String, Set<String>> entry : MATRIZ_ROLES.entrySet()) {
            String nombre = entry.getKey();
            Set<String> codigos = entry.getValue();

            Rol rol = rolRepository.findByNombre(nombre).orElseGet(() ->
                    rolRepository.save(Rol.builder()
                            .nombre(nombre)
                            .descripcion(descripcionRol(nombre))
                            .permisos(new HashSet<>())
                            .build()));

            boolean cambios = false;
            for (String codigo : codigos) {
                Permiso permiso = permisosPorCodigo.get(codigo);
                if (permiso != null && rol.getPermisos().add(permiso)) {
                    cambios = true;
                }
            }
            if (cambios) {
                rolRepository.save(rol);
            }
        }
    }

    private void sembrarUsuarioAdmin() {
        usuarioRepository.findByEmail(ADMIN_EMAIL).ifPresentOrElse(
                usuario -> log.info("Usuario admin ya existe: {}", ADMIN_EMAIL),
                () -> {
                    Rol admin = rolRepository.findByNombre("ADMIN")
                            .orElseThrow(() -> new IllegalStateException(
                                    "No existe el rol ADMIN para el usuario administrador"));
                    usuarioRepository.save(Usuario.builder()
                            .nombre("Administrador")
                            .email(ADMIN_EMAIL)
                            .password(passwordEncoder.encode(ADMIN_PASSWORD))
                            .telefono("0999999999")
                            .rol(admin)
                            .activo(true)
                            .build());
                    log.info("Usuario admin creado: {}", ADMIN_EMAIL);
                });
    }

    private void sembrarGuiasSistema() {
        List<GuiaSistema> guias = List.of(
                guia("PRODUCTOS", "/productos", "Registrar un producto",
                        "Permite crear un producto con su descripcion, categoria, precios y stock.",
                        "[\"Abrir Productos en /productos.\",\"Seleccionar Nuevo producto.\",\"Completar los datos y guardar.\"]",
                        "registrar, crear, producto, nuevo"),
                guia("CATEGORIAS", "/categorias", "Crear una categoria",
                        "Permite organizar productos mediante categorias.",
                        "[\"Abrir Categorias en /categorias.\",\"Seleccionar Nueva categoria.\",\"Ingresar el nombre y guardar.\"]",
                        "crear, categoria, organizar"),
                guia("CLIENTES", "/clientes", "Registrar un cliente",
                        "Permite registrar los datos de contacto y comerciales de un cliente.",
                        "[\"Abrir Clientes en /clientes.\",\"Seleccionar Nuevo cliente.\",\"Completar los datos y guardar.\"]",
                        "registrar, crear, cliente, nuevo"),
                guia("PROVEEDORES", "/proveedores", "Registrar un proveedor",
                        "Permite registrar proveedores para gestionar las compras.",
                        "[\"Abrir Proveedores en /proveedores.\",\"Seleccionar Nuevo proveedor.\",\"Completar los datos y guardar.\"]",
                        "registrar, crear, proveedor, nuevo"),
                guia("VENTAS", "/ventas", "Realizar una venta",
                        "Permite seleccionar un cliente, agregar productos y registrar una venta.",
                        "[\"Abrir Ventas en /ventas.\",\"Seleccionar Nueva venta.\",\"Agregar cliente y productos.\",\"Confirmar la venta.\"]",
                        "venta, vender, factura, cliente"),
                guia("COMPRAS", "/compras", "Registrar una compra",
                        "Permite registrar compras de productos a un proveedor.",
                        "[\"Abrir Compras en /compras.\",\"Seleccionar Nueva compra.\",\"Elegir proveedor y productos.\",\"Guardar la compra.\"]",
                        "compra, proveedor, abastecimiento"),
                guia("GASTOS", "/gastos", "Registrar un gasto",
                        "Permite registrar gastos operativos del negocio.",
                        "[\"Abrir Gastos en /gastos.\",\"Seleccionar Nuevo gasto.\",\"Ingresar descripcion, monto y fecha.\",\"Guardar el gasto.\"]",
                        "registrar, gasto, monto"),
                guia("USUARIOS", "/usuarios", "Crear un usuario",
                        "Permite crear usuarios y asignarles un rol.",
                        "[\"Abrir Usuarios en /usuarios.\",\"Seleccionar Nuevo usuario.\",\"Completar los datos y asignar un rol.\",\"Guardar.\"]",
                        "crear, usuario, rol, acceso"),
                guia("ROLES", "/roles", "Administrar roles",
                        "Permite crear roles y administrar sus permisos.",
                        "[\"Abrir Roles en /roles.\",\"Seleccionar un rol o crear uno nuevo.\",\"Ajustar permisos y guardar.\"]",
                        "rol, permiso, administrar"),
                guia("LOGS", "/logs", "Consultar logs",
                        "Permite consultar la auditoria de acciones del sistema.",
                        "[\"Abrir Logs en /logs.\",\"Aplicar filtros de fecha o usuario.\",\"Revisar los resultados.\"]",
                        "logs, auditoria, consultar"));

        guias.forEach(guia -> guiaSistemaRepository
                .findByModuloAndRutaAndTitulo(guia.getModulo(), guia.getRuta(), guia.getTitulo())
                .orElseGet(() -> guiaSistemaRepository.save(guia)));
        log.info("Guias del sistema verificadas: {}", guiaSistemaRepository.count());
    }

    private GuiaSistema guia(String modulo, String ruta, String titulo, String descripcion,
                             String pasos, String keywords) {
        return GuiaSistema.builder()
                .modulo(modulo)
                .ruta(ruta)
                .titulo(titulo)
                .descripcion(descripcion)
                .pasos(pasos)
                .keywords(keywords)
                .build();
    }

    private String descripcionRol(String nombre) {
        return switch (nombre) {
            case "ADMIN" -> "Acceso total al sistema. Gestión de usuarios, configuraciones y todos los módulos.";
            case "VENDEDOR" -> "Gestión de ventas, clientes y consulta de productos.";
            case "BODEGUERO" -> "Gestión de inventario, productos, compras y movimientos de stock.";
            default -> null;
        };
    }
}
