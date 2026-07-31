package com.ferreplus.service;

import com.ferreplus.dto.RolDTO;
import com.ferreplus.dto.RolRequestDTO;
import com.ferreplus.entity.Permiso;
import com.ferreplus.entity.Rol;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.exception.ConflictException;
import com.ferreplus.exception.ResourceNotFoundException;
import com.ferreplus.repository.PermisoRepository;
import com.ferreplus.repository.RolRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
@RequiredArgsConstructor
public class RolService {

    private final RolRepository rolRepository;
    private final PermisoRepository permisoRepository;
    private final UsuarioRepository usuarioRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public List<Rol> list() {
        return rolRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Rol getById(Long id) {
        return rolRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Rol no encontrado con id: " + id));
    }

    @Transactional(readOnly = true)
    public List<RolDTO> listDTO() {
        return rolRepository.findAllWithPermisos().stream()
                .map(this::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public RolDTO getDTO(Long id) {
        Rol rol = rolRepository.findWithPermisosById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Rol no encontrado con id: " + id));
        return toDTO(rol);
    }

    public RolDTO create(RolRequestDTO dto) {
        validarNombreUnico(dto.getNombre(), null);

        Set<Permiso> matriz = resolverMatriz(dto.getPermisos());

        Rol rol = Rol.builder()
                .nombre(dto.getNombre())
                .descripcion(dto.getDescripcion())
                .permisos(matriz)
                .build();

        rol = rolRepository.save(rol);

        auditService.registrarEvento("ROL", rol.getId(), "CREAR", jsonDetalle(rol));
        return toDTO(rol);
    }

    public RolDTO update(Long id, RolRequestDTO dto) {
        Rol rol = getById(id);
        validarNombreUnico(dto.getNombre(), id);

        Set<String> actuales = rol.getPermisos().stream()
                .map(Permiso::getCodigo)
                .collect(Collectors.toSet());
        Set<String> nuevas = dto.getPermisos() == null
                ? new HashSet<>()
                : new HashSet<>(dto.getPermisos());
        Set<String> agregados = nuevas.stream().filter(c -> !actuales.contains(c))
                .collect(Collectors.toCollection(java.util.TreeSet::new));
        Set<String> quitados = actuales.stream().filter(c -> !nuevas.contains(c))
                .collect(Collectors.toCollection(java.util.TreeSet::new));

        rol.setNombre(dto.getNombre());
        rol.setDescripcion(dto.getDescripcion());
        rol.getPermisos().clear();
        rol.getPermisos().addAll(resolverMatriz(dto.getPermisos()));

        rolRepository.save(rol);

        auditService.registrarEvento("ROL", rol.getId(), "ACTUALIZAR",
                jsonDetalleUpdate(rol, agregados, quitados));
        return toDTO(rol);
    }

    public void delete(Long id) {
        Rol rol = getById(id);

        if (usuarioRepository.countByRolIdAndActivoTrue(id) > 0) {
            throw new ConflictException("No se puede eliminar el rol: tiene usuarios activos asignados");
        }
        if (usuarioRepository.countByRolId(id) > 0) {
            throw new ConflictException("No se puede eliminar el rol: tiene usuarios asignados (incluidos inactivos)");
        }

        rolRepository.delete(rol);
        auditService.registrarEvento("ROL", id, "ELIMINAR", null);
    }

    private void validarNombreUnico(String nombre, Long idExcluido) {
        rolRepository.findByNombre(nombre).ifPresent(existente -> {
            if (idExcluido == null || !existente.getId().equals(idExcluido)) {
                throw new BadRequestException("Ya existe un rol con el nombre: " + nombre);
            }
        });
    }

    private Set<Permiso> resolverMatriz(List<String> codigos) {
        Set<String> codigosSet = codigos == null
                ? new HashSet<>()
                : new HashSet<>(codigos.stream().filter(c -> c != null && !c.isBlank()).toList());

        if (codigosSet.isEmpty()) {
            return new HashSet<>();
        }

        List<Permiso> encontrados = permisoRepository.findByCodigoIn(codigosSet);
        if (encontrados.size() != codigosSet.size()) {
            Set<String> presentes = encontrados.stream().map(Permiso::getCodigo).collect(Collectors.toSet());
            Set<String> inexistentes = codigosSet.stream()
                    .filter(c -> !presentes.contains(c))
                    .collect(Collectors.toCollection(java.util.TreeSet::new));
            throw new BadRequestException("Códigos de permiso inexistentes: " + inexistentes);
        }
        return new HashSet<>(encontrados);
    }

    private RolDTO toDTO(Rol rol) {
        RolDTO dto = new RolDTO();
        dto.setId(rol.getId());
        dto.setNombre(rol.getNombre());
        dto.setDescripcion(rol.getDescripcion());

        List<String> codigos = rol.getPermisos().stream()
                .map(Permiso::getCodigo)
                .sorted()
                .toList();
        dto.setPermisos(codigos);
        return dto;
    }

    private String jsonDetalle(Rol rol) {
        try {
            return objectMapper.writeValueAsString(toDTO(rol));
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    private String jsonDetalleUpdate(Rol rol, Set<String> agregados, Set<String> quitados) {
        try {
            return objectMapper.writeValueAsString(Map.of(
                    "rol", toDTO(rol),
                    "permisosAgregados", agregados,
                    "permisosQuitados", quitados
            ));
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }
}
