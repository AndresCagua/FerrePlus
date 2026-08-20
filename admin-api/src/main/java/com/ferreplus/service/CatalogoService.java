package com.ferreplus.service;

import com.ferreplus.dto.ModuloDTO;
import com.ferreplus.dto.PermisoDTO;
import com.ferreplus.entity.Modulo;
import com.ferreplus.entity.Permiso;
import com.ferreplus.repository.ModuloRepository;
import com.ferreplus.repository.PermisoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Catálogo dinámico de módulos y permisos para la UI de roles/usuarios (R2).
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CatalogoService {

    private final ModuloRepository moduloRepository;
    private final PermisoRepository permisoRepository;

    public List<ModuloDTO> getModulosConPermisos() {
        return moduloRepository.findAllByOrderByOrdenAsc().stream()
                .map(this::toModuloDTO)
                .toList();
    }

    public List<PermisoDTO> getPermisos() {
        return permisoRepository.findAll().stream()
                .map(this::toPermisoDTO)
                .toList();
    }

    private ModuloDTO toModuloDTO(Modulo modulo) {
        ModuloDTO dto = new ModuloDTO();
        dto.setId(modulo.getId());
        dto.setNombre(modulo.getNombre());
        dto.setCodigo(modulo.getCodigo());
        dto.setOrden(modulo.getOrden());

        List<PermisoDTO> permisos = modulo.getPermisos().stream()
                .map(this::toPermisoDTO)
                .toList();
        dto.setPermisos(permisos);
        return dto;
    }

    private PermisoDTO toPermisoDTO(Permiso permiso) {
        PermisoDTO dto = new PermisoDTO();
        dto.setId(permiso.getId());
        dto.setCodigo(permiso.getCodigo());
        dto.setNombre(permiso.getNombre());
        dto.setAccion(permiso.getAccion());
        dto.setModuloId(permiso.getModulo().getId());
        dto.setModuloCodigo(permiso.getModulo().getCodigo());
        dto.setModuloNombre(permiso.getModulo().getNombre());
        return dto;
    }
}
