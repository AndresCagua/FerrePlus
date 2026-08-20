package com.ferreplus.repository;

import com.ferreplus.entity.GuiaSistema;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GuiaSistemaRepository extends JpaRepository<GuiaSistema, Long> {

    List<GuiaSistema> findByModulo(String modulo);

    Optional<GuiaSistema> findByModuloAndRutaAndTitulo(String modulo, String ruta, String titulo);
}
