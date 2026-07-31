package com.ferreplus.repository;

import com.ferreplus.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByEmail(String email);

    /**
     * Resuelve usuario + rol + matriz de permisos del rol + overrides en una
     * sola query (anti N+1). LEFT JOIN para no excluir usuarios sin permisos
     * ni overrides. Usado por el filtro JWT en cada request y por el login.
     */
    @Query("""
            SELECT DISTINCT u FROM Usuario u
            JOIN FETCH u.rol r
            LEFT JOIN FETCH r.permisos
            LEFT JOIN FETCH u.overrides up
            LEFT JOIN FETCH up.permiso
            WHERE u.email = :email
            """)
    Optional<Usuario> findWithPermisosByEmail(@Param("email") String email);

    @Query("""
            SELECT DISTINCT u FROM Usuario u
            JOIN FETCH u.rol r
            LEFT JOIN FETCH r.permisos
            LEFT JOIN FETCH u.overrides up
            LEFT JOIN FETCH up.permiso
            WHERE u.id = :id
            """)
    Optional<Usuario> findWithPermisosById(@Param("id") Long id);

    @Query("""
            SELECT DISTINCT u FROM Usuario u
            JOIN FETCH u.rol r
            LEFT JOIN FETCH r.permisos
            LEFT JOIN FETCH u.overrides up
            LEFT JOIN FETCH up.permiso
            """)
    List<Usuario> findAllWithPermisos();

    long countByRolIdAndActivoTrue(Long rolId);

    long countByRolId(Long rolId);
}
