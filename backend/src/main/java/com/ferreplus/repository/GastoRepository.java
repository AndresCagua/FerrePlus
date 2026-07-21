package com.ferreplus.repository;

import com.ferreplus.entity.Gasto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface GastoRepository extends JpaRepository<Gasto, Long> {

    List<Gasto> findAllByOrderByFechaCreacionDesc();

    @Query("SELECT COALESCE(SUM(g.monto), 0) FROM Gasto g WHERE g.fechaGasto BETWEEN :desde AND :hasta")
    BigDecimal sumMontoByFechaGastoBetween(@Param("desde") LocalDate desde, @Param("hasta") LocalDate hasta);
}
