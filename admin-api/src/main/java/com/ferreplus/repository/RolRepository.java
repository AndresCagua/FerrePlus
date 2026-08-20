package com.ferreplus.repository;

import com.ferreplus.entity.Rol;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RolRepository extends JpaRepository<Rol, Long> {

    Optional<Rol> findByNombre(String nombre);

    /**
     * Rol + matriz de permisos en una sola query (anti N+1). Usado por
     * RolService.listDTO() para mapear las matrices sin accesos LAZY por fila.
     */
    @Query("""
            SELECT DISTINCT r FROM Rol r
            LEFT JOIN FETCH r.permisos
            """)
    List<Rol> findAllWithPermisos();

    @Query("""
            SELECT DISTINCT r FROM Rol r
            LEFT JOIN FETCH r.permisos
            WHERE r.id = :id
            """)
    Optional<Rol> findWithPermisosById(@Param("id") Long id);
}