package com.ferreplus.service;

import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Usuario;
import com.ferreplus.repository.AuditoriaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Infraestructura genérica de auditoría (R10, Decisión 7).
 *
 * {@code Propagation.MANDATORY} exige que el llamador ya tenga una transacción:
 * el registro es ATÓMICO con la operación auditada — si la operación falla y
 * hace rollback, la fila de auditoría también revierte; si el save falla, la
 * operación completa revierte. El usuario se resuelve desde el contexto de
 * seguridad; queda null para eventos de sistema/seed.
 */
@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditoriaRepository auditoriaRepository;

    @Transactional(propagation = Propagation.MANDATORY)
    public void registrarEvento(String entidad, Long entidadId, String accion, String detalle) {
        registrarEvento(entidad, entidadId, accion, detalle, usuarioActual());
    }

    /**
     * Overload con actor explícito (R5): usado cuando el {@code SecurityContextHolder}
     * aún no refleja al usuario autenticado — p. ej. dentro de {@code AuthService.login()}
     * antes de que el contexto se actualice. Mantiene {@code MANDATORY} (atomicidad R10).
     * {@code usuario == null} representa eventos de sistema/seed.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void registrarEvento(String entidad, Long entidadId, String accion, String detalle, Usuario usuario) {
        auditoriaRepository.save(Auditoria.builder()
                .entidad(entidad)
                .entidadId(entidadId)
                .accion(accion)
                .usuario(usuario)
                .detalle(detalle)
                .build());
    }

    private Usuario usuarioActual() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Usuario usuario) {
            return usuario;
        }
        return null;
    }
}
