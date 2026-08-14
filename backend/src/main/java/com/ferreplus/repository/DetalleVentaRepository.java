package com.ferreplus.repository;

import com.ferreplus.entity.DetalleVenta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DetalleVentaRepository extends JpaRepository<DetalleVenta, Long> {

    List<DetalleVenta> findByVentaId(Long ventaId);

    @Query("SELECT d FROM DetalleVenta d JOIN FETCH d.venta v JOIN FETCH d.producto p "
            + "WHERE v.estado = :estado")
    List<DetalleVenta> findAllWithVentaAndProductoByVentaEstado(@Param("estado") String estado);
}
