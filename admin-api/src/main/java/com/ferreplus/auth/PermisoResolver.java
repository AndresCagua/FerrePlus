package com.ferreplus.auth;

import com.ferreplus.entity.Permiso;
import com.ferreplus.entity.Usuario;
import com.ferreplus.entity.UsuarioPermiso;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Resolución de autoridades (R5): permisos efectivos = permisos(rol)
 * ∪ {concedido=true} ∖ {concedido=false} — la denegación aplica DESPUÉS de la
 * unión (edge case 10: el override concedido=false gana sobre el rol).
 *
 * Componente compartido sin dependencias de Spring, usado por el login
 * (CustomUserDetailsService), el filtro JWT (cada request) y la construcción de
 * UsuarioDTO.permisos, para que la semántica sea idéntica en todos los puntos.
 */
@Component
public class PermisoResolver {

    public Set<String> codigosEfectivos(Usuario usuario) {
        Set<String> codigos = new HashSet<>();

        if (usuario.getRol() != null) {
            for (Permiso p : usuario.getRol().getPermisos()) {
                codigos.add(p.getCodigo());
            }
        }

        if (usuario.getOverrides() != null) {
            for (UsuarioPermiso up : usuario.getOverrides()) {
                if (up.isConcedido()) {
                    codigos.add(up.getPermiso().getCodigo());
                }
            }
            for (UsuarioPermiso up : usuario.getOverrides()) {
                if (!up.isConcedido()) {
                    codigos.remove(up.getPermiso().getCodigo());
                }
            }
        }

        return codigos;
    }

    public List<GrantedAuthority> resolverAutoridades(Usuario usuario) {
        List<GrantedAuthority> authorities = new ArrayList<>();

        for (String codigo : codigosEfectivos(usuario)) {
            authorities.add(new SimpleGrantedAuthority(codigo));
        }

        if (usuario.getRol() != null) {
            // Autoridad transitoria para compatibilidad (R5)
            authorities.add(new SimpleGrantedAuthority("ROLE_" + usuario.getRol().getNombre()));
        }

        return authorities;
    }
}
