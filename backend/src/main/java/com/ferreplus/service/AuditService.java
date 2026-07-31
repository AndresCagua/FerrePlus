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
        auditoriaRepository.save(Auditoria.builder()
                .entidad(entidad)
                .entidadId(entidadId)
                .accion(accion)
                .usuario(usuarioActual())
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
