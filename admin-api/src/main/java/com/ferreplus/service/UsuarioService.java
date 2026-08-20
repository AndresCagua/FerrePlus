package com.ferreplus.service;

import com.ferreplus.auth.PermisoResolver;
import com.ferreplus.dto.CambioPasswordDTO;
import com.ferreplus.dto.UsuarioDTO;
import com.ferreplus.dto.UsuarioPermisoDTO;
import com.ferreplus.dto.UsuarioPermisoRequestDTO;
import com.ferreplus.dto.UsuarioRequestDTO;
import com.ferreplus.entity.Permiso;
import com.ferreplus.entity.Rol;
import com.ferreplus.entity.Usuario;
import com.ferreplus.entity.UsuarioPermiso;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.PermisoRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@Transactional
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final RolService rolService;
    private final PasswordEncoder passwordEncoder;
    private final PermisoRepository permisoRepository;
    private final PermisoResolver permisoResolver;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<Usuario> list() {
        return usuarioRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Usuario getById(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado con id: " + id));
    }

    @Transactional(readOnly = true)
    public List<UsuarioDTO> listDTO() {
        return usuarioRepository.findAllWithPermisos().stream()
                .map(this::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public UsuarioDTO getDTO(Long id) {
        Usuario usuario = usuarioRepository.findWithPermisosById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado con id: " + id));
        return toDTO(usuario);
    }

    public UsuarioDTO create(UsuarioRequestDTO dto) {
        if (dto.getPassword() == null || dto.getPassword().isBlank()) {
            throw new BadRequestException("La contraseña es obligatoria");
        }

        if (usuarioRepository.findByEmail(dto.getEmail()).isPresent()) {
            throw new BadRequestException("El email ya está registrado");
        }

        Rol rol = rolService.getById(dto.getRolId());
        validarOverrides(dto.getOverrides());

        Usuario usuario = Usuario.builder()
                .nombre(dto.getNombre())
                .email(dto.getEmail())
                .password(passwordEncoder.encode(dto.getPassword()))
                .telefono(dto.getTelefono())
                .rol(rol)
                .activo(true)
                .build();
        usuario.setOverrides(construirOverrides(usuario, dto.getOverrides()));

        usuario = usuarioRepository.save(usuario);

        auditService.registrarEvento("USUARIO", usuario.getId(), "CREAR", jsonDetalle(usuario));
        return toDTO(usuario);
    }

    public UsuarioDTO update(Long id, UsuarioRequestDTO dto) {
        Usuario usuario = getById(id);
        validarOverrides(dto.getOverrides());

        usuario.setNombre(dto.getNombre());
        usuario.setTelefono(dto.getTelefono());
        usuario.setActivo(true);

        if (dto.getEmail() != null && !dto.getEmail().equals(usuario.getEmail())) {
            if (usuarioRepository.findByEmail(dto.getEmail()).isPresent()) {
                throw new BadRequestException("El email ya está registrado");
            }
            usuario.setEmail(dto.getEmail());
        }

        if (dto.getRolId() != null) {
            usuario.setRol(rolService.getById(dto.getRolId()));
        }

        if (dto.getPassword() != null && !dto.getPassword().isBlank()) {
            usuario.setPassword(passwordEncoder.encode(dto.getPassword()));
        }

        // Reemplazo de overrides: la lista vacía elimina todos (R4)
        usuario.getOverrides().clear();
        usuario.getOverrides().addAll(construirOverrides(usuario, dto.getOverrides()));

        usuario = usuarioRepository.save(usuario);

        auditService.registrarEvento("USUARIO", id, "ACTUALIZAR", jsonDetalle(usuario));
        return toDTO(usuario);
    }

    public void delete(Long id) {
        Usuario usuario = getById(id);
        usuario.setActivo(false);
        usuarioRepository.save(usuario);
        auditService.registrarEvento("USUARIO", id, "ELIMINAR", null);
    }

    @Transactional(readOnly = true)
    public Usuario getByEmail(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado con email: " + email));
    }

    public void cambiarPassword(Long id, CambioPasswordDTO dto) {
        Usuario usuario = getById(id);

        if (!passwordEncoder.matches(dto.getPasswordActual(), usuario.getPassword())) {
            throw new BadRequestException("La contraseña actual no es correcta");
        }

        usuario.setPassword(passwordEncoder.encode(dto.getNuevoPassword()));
        usuarioRepository.save(usuario);
        auditService.registrarEvento("USUARIO", id, "PASSWORD", null);
    }

    /**
     * Mapeo a {@link UsuarioDTO} con permisos EFECTIVOS (rol ∪ overrides)
     * y la lista de overrides. Público para {@code GET /api/usuarios/me},
     * donde el principal ya viene resuelto por el filtro JWT.
     */
    public UsuarioDTO toDTO(Usuario usuario) {
        UsuarioDTO dto = new UsuarioDTO();
        dto.setId(usuario.getId());
        dto.setNombre(usuario.getNombre());
        dto.setEmail(usuario.getEmail());
        dto.setTelefono(usuario.getTelefono());
        dto.setActivo(usuario.isActivo());

        if (usuario.getRol() != null) {
            dto.setRolId(usuario.getRol().getId());
            dto.setRolNombre(usuario.getRol().getNombre());
        }

        List<String> permisos = permisoResolver.codigosEfectivos(usuario).stream()
                .sorted()
                .toList();
        dto.setPermisos(permisos);

        List<UsuarioPermisoDTO> overrides = usuario.getOverrides().stream()
                .map(up -> new UsuarioPermisoDTO(up.getPermiso().getCodigo(), up.isConcedido()))
                .sorted(Comparator.comparing(UsuarioPermisoDTO::getPermisoCodigo))
                .toList();
        dto.setOverrides(overrides);

        return dto;
    }

    /**
     * Valida los overrides del request (R4): código obligatorio, sin duplicados
     * (un mismo permiso con concedido=true y false cae aquí → 400) y código
     * existente en el catálogo → 400.
     */
    private void validarOverrides(List<UsuarioPermisoRequestDTO> overrides) {
        if (overrides == null || overrides.isEmpty()) {
            return;
        }

        Set<String> vistos = new HashSet<>();
        for (UsuarioPermisoRequestDTO o : overrides) {
            if (o.getPermisoCodigo() == null || o.getPermisoCodigo().isBlank()) {
                throw new BadRequestException("Cada override debe incluir permisoCodigo");
            }
            if (!vistos.add(o.getPermisoCodigo())) {
                throw new BadRequestException("Override duplicado para el permiso: " + o.getPermisoCodigo());
            }
        }

        List<Permiso> encontrados = permisoRepository.findByCodigoIn(vistos);
        if (encontrados.size() != vistos.size()) {
            Set<String> presentes = encontrados.stream().map(Permiso::getCodigo)
                    .collect(java.util.stream.Collectors.toSet());
            Set<String> inexistentes = vistos.stream()
                    .filter(c -> !presentes.contains(c))
                    .collect(java.util.stream.Collectors.toCollection(java.util.TreeSet::new));
            throw new BadRequestException("Códigos de permiso inexistentes en overrides: " + inexistentes);
        }
    }

    private Set<UsuarioPermiso> construirOverrides(Usuario usuario, List<UsuarioPermisoRequestDTO> overrides) {
        Set<UsuarioPermiso> resultado = new HashSet<>();
        if (overrides == null) {
            return resultado;
        }
        for (UsuarioPermisoRequestDTO o : overrides) {
            Permiso permiso = permisoRepository.findByCodigo(o.getPermisoCodigo())
                    .orElseThrow(() -> new BadRequestException("Código de permiso inexistente: " + o.getPermisoCodigo()));
            resultado.add(UsuarioPermiso.builder()
                    .usuario(usuario)
                    .permiso(permiso)
                    .concedido(o.isConcedido())
                    .build());
        }
        return resultado;
    }

    private String jsonDetalle(Usuario usuario) {
        try {
            return objectMapper.writeValueAsString(toDTO(usuario));
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }
}
