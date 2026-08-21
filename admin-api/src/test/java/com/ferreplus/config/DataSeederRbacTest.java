package com.ferreplus.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Field;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

class DataSeederRbacTest {
    @Test
    @SuppressWarnings("unchecked")
    void adminMatrixIncludesAllNewModulesAndActions() throws Exception {
        Field matrixField = DataSeeder.class.getDeclaredField("MATRIZ_ROLES");
        matrixField.setAccessible(true);
        Set<String> admin = ((Map<String, Set<String>>) matrixField.get(null)).get("ADMIN");
        assertThat(admin).contains("TALENTO_PUBLICACIONES_VER", "TALENTO_PUBLICACIONES_CREAR", "TALENTO_PUBLICACIONES_EDITAR", "TALENTO_PUBLICACIONES_ELIMINAR");
        assertThat(admin).contains("TALENTO_CONVOCATORIAS_VER", "TALENTO_POSTULACIONES_VER", "TALENTO_DESTINATARIOS_VER", "CONTABILIDAD_CONTACTOS_VER");
    }

    @Test
    @SuppressWarnings("unchecked")
    void catalogoContieneModulosNuevosConOrdenEstable() throws Exception {
        Field modulesField = DataSeeder.class.getDeclaredField("MODULOS");
        modulesField.setAccessible(true);
        Map<String, int[]> modules = (Map<String, int[]>) modulesField.get(null);
        assertThat(modules.keySet()).containsExactly("DASHBOARD", "PRODUCTOS", "CATEGORIAS", "PROVEEDORES", "CLIENTES", "VENTAS", "COMPRAS", "PRECIOS", "MOVIMIENTOS", "GASTOS", "USUARIOS", "ROLES", "REPORTES", "LOGS", "CHAT", "TALENTO_PUBLICACIONES", "TALENTO_CONVOCATORIAS", "TALENTO_POSTULACIONES", "TALENTO_DESTINATARIOS", "CONTABILIDAD_CONTACTOS");
    }
}
