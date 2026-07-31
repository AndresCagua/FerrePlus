package com.ferreplus.repository;

import com.ferreplus.entity.UsuarioPermiso;
import com.ferreplus.entity.UsuarioPermisoId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UsuarioPermisoRepository extends JpaRepository<UsuarioPermiso, UsuarioPermisoId> {
}
