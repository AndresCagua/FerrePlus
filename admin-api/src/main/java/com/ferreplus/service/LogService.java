package com.ferreplus.service;

import com.ferreplus.dto.AuditoriaDTO;
import com.ferreplus.dto.UsuarioOpcionDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.repository.AuditoriaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Consulta paginada/filtrada y borrado por rango de la tabla {@code auditoria} (R2/R3).
 *
 * <p>Los filtros son opcionales; el rango de borrado es obligatorio y validado
 * (400 por ausencia, formato inválido o {@code hasta < desde}). El borrado es un
 * bulk single-statement vía {@link AuditoriaRepository#borrarPorRango} (D4) y NO se
 * auto-audita (excepción consciente D6). La consulta expone solo {@link AuditoriaDTO},
 * nunca la entidad JPA.</p>
 */
@Service
@RequiredArgsConstructor
public class LogService {

    private final AuditoriaRepository auditoriaRepository;

    @Transactional(readOnly = true)
    public Page<AuditoriaDTO> consultar(String fechaDesde, String fechaHasta, Long usuarioId,
                                        String entidad, String accion, String usuarioNombre,
                                        Pageable pageable) {
        LocalDateTime desde = parseFiltro(fechaDesde, true);
        LocalDateTime hasta = parseFiltro(fechaHasta, false);

        Specification<Auditoria> spec = Specification.where(null);
        if (desde != null) {
            spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("fecha"), desde));
        }
        if (hasta != null) {
            spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("fecha"), hasta));
        }
        if (usuarioId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("usuario").get("id"), usuarioId));
        }
        if (entidadPresente(usuarioNombre)) {
            // Contiene (LIKE %valor%) sobre usuario.nombre, case-insensitive.
            // .as(String.class) convierte el Path<Object> a Expression<String> para cb.lower.
            spec = spec.and((root, query, cb) -> cb.like(
                    cb.lower(root.get("usuario").get("nombre").as(String.class)),
                    "%" + usuarioNombre.trim().toLowerCase() + "%"));
        }
        if (entidadPresente(entidad)) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("entidad"), entidad.trim().toUpperCase()));
        }
        if (entidadPresente(accion)) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("accion"), accion.trim().toUpperCase()));
        }

        return auditoriaRepository.findAll(spec, pageable).map(this::toDTO);
    }

    @Transactional
    public int eliminarPorRango(String desde, String hasta) {
        LocalDateTime ds = parseObligatorio(desde, true);
        LocalDateTime hs = parseObligatorio(hasta, false);
        if (hs.isBefore(ds)) {
            throw new BadRequestException("El rango de fechas es inválido: 'hasta' es anterior a 'desde'");
        }
        return auditoriaRepository.borrarPorRango(ds, hs);
    }

    /**
     * Opciones para el selector de usuarios del filtro de logs (R7 refinamiento):
     * usuarios con al menos una fila de auditoría, solo {@code id} + {@code nombre}.
     * No requiere {@code USUARIOS_VER}: el permiso de consulta es {@code LOGS_VER}.
     */
    @Transactional(readOnly = true)
    public List<UsuarioOpcionDTO> listarUsuariosConActividad() {
        return auditoriaRepository.findUsuariosConActividad().stream()
                .map(fila -> new UsuarioOpcionDTO((Long) fila[0], (String) fila[1]))
                .toList();
    }

    private AuditoriaDTO toDTO(Auditoria auditoria) {
        AuditoriaDTO dto = new AuditoriaDTO();
        dto.setId(auditoria.getId());
        dto.setEntidad(auditoria.getEntidad());
        dto.setEntidadId(auditoria.getEntidadId());
        dto.setAccion(auditoria.getAccion());
        dto.setFecha(auditoria.getFecha());
        dto.setDetalle(auditoria.getDetalle());
        if (auditoria.getUsuario() != null) {
            dto.setUsuarioId(auditoria.getUsuario().getId());
            dto.setUsuarioNombre(auditoria.getUsuario().getNombre());
        }
        return dto;
    }

    /**
     * Filtro opcional: ausente/vacío → {@code null} (no filtra); inválido → {@code null}
     * (se ignora, tabla de parse D4). No lanza 400 en GET: el error 400 está reservado
     * al borrado por rango (DELETE).
     */
    private LocalDateTime parseFiltro(String valor, boolean esDesde) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        try {
            return parseDual(valor, esDesde);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /**
     * Borrado: el rango es obligatorio → 400 si falta/vacío o el formato no se
     * parsea. Ninguno de estos borra filas (R3).
     */
    private LocalDateTime parseObligatorio(String valor, boolean esDesde) {
        if (valor == null || valor.isBlank()) {
            throw new BadRequestException("Debe proporcionar 'desde' y 'hasta' para borrar logs por rango");
        }
        try {
            return parseDual(valor, esDesde);
        } catch (DateTimeParseException e) {
            throw new BadRequestException(
                    "Formato de fecha inválido: " + valor + " (use yyyy-MM-dd o yyyy-MM-dd'T'HH:mm:ss)");
        }
    }

    /**
     * Parse dual (Decisión 4): {@code yyyy-MM-dd} → {@code startOfDay} para el
     * límite inferior y {@code endOfDay} (LocalTime.MAX) para el superior (rango de
     * día completo e inclusivo); {@code yyyy-MM-dd'T'HH:mm:ss} se usa literal.
     */
    private LocalDateTime parseDual(String valor, boolean esDesde) {
        if (valor.contains("T")) {
            return LocalDateTime.parse(valor);
        }
        LocalDate fecha = LocalDate.parse(valor);
        return esDesde ? fecha.atStartOfDay() : fecha.atTime(LocalTime.MAX);
    }

    private boolean entidadPresente(String valor) {
        return valor != null && !valor.isBlank();
    }
}