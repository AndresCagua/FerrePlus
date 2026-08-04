package com.ferreplus.repository;

import com.ferreplus.entity.Auditoria;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AuditoriaRepository
        extends JpaRepository<Auditoria, Long>, JpaSpecificationExecutor<Auditoria> {

    List<Auditoria> findByEntidadAndEntidadIdAndAccion(String entidad, Long entidadId, String accion);

    /**
     * Consulta paginada con filtros dinámicos (R2). {@code @EntityGraph("usuario")}
     * evita N+1 al resolver la relación LAZY {@code auditoria.usuario} dentro de la
     * página (Decisión 1, diseño).
     */
    @Override
    @EntityGraph(attributePaths = "usuario")
    Page<Auditoria> findAll(Specification<Auditoria> spec, Pageable pageable);

    /**
     * Borrado masivo por rango de fechas (R3, Decisión 4): un SOLO statement SQL,
     * sin materializar filas. {@code clearAutomatically} evita entidades stale y
     * {@code flushAutomatically} fuerzan flush antes del DELETE. Devuelve el conteo.
     */
    @Transactional
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM Auditoria a WHERE a.fecha BETWEEN :desde AND :hasta")
    int borrarPorRango(@Param("desde") LocalDateTime desde, @Param("hasta") LocalDateTime hasta);

    /**
     * Usuarios con al menos una fila de auditoría (selector del filtro de logs,
     * R7 refinamiento). Devuelve solo {@code id} y {@code nombre}, sin email ni
     * datos sensibles. Los ids se agrupan de a pares {@code [id, nombre]}.
     */
    @Query("SELECT DISTINCT u.id, u.nombre FROM Auditoria a JOIN a.usuario u ORDER BY u.nombre")
    List<Object[]> findUsuariosConActividad();
}