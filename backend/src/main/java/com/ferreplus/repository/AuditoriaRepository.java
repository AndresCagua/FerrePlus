package com.ferreplus.repository;

import com.ferreplus.entity.Auditoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuditoriaRepository extends JpaRepository<Auditoria, Long> {

    List<Auditoria> findByEntidadAndEntidadIdAndAccion(String entidad, Long entidadId, String accion);
}
