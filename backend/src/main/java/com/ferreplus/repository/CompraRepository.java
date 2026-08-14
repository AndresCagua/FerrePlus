package com.ferreplus.repository;

import com.ferreplus.entity.Compra;
import com.ferreplus.service.chat.ProveedorCompraTotalProjection;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface CompraRepository extends JpaRepository<Compra, Long> {

    List<Compra> findAllByOrderByFechaCreacionDesc();

    List<Compra> findByFechaCreacionBetweenOrderByFechaCreacionDesc(LocalDateTime desde, LocalDateTime hasta);

    Optional<Compra> findFirstByEstadoOrderByTotalDescIdAsc(String estado);

    Optional<Compra> findFirstByEstadoAndFechaFacturaBetweenOrderByTotalDescIdAsc(
            String estado, LocalDate from, LocalDate to);

    @Query("""
            SELECT c.proveedor.id AS proveedorId, MAX(c.proveedor.nombre) AS proveedorNombre,
                   SUM(c.total) AS totalAcumulado
            FROM Compra c
            WHERE c.estado = :estado
            GROUP BY c.proveedor.id
            ORDER BY SUM(c.total) DESC, c.proveedor.id ASC
            """)
    List<ProveedorCompraTotalProjection> findProveedorTotalsByEstado(
            @Param("estado") String estado, Pageable pageable);

    @Query("""
            SELECT c.proveedor.id AS proveedorId, MAX(c.proveedor.nombre) AS proveedorNombre,
                   SUM(c.total) AS totalAcumulado
            FROM Compra c
            WHERE c.estado = :estado AND c.fechaFactura BETWEEN :from AND :to
            GROUP BY c.proveedor.id
            ORDER BY SUM(c.total) DESC, c.proveedor.id ASC
            """)
    List<ProveedorCompraTotalProjection> findProveedorTotalsByEstadoAndFechaFacturaBetween(
            @Param("estado") String estado, @Param("from") LocalDate from,
            @Param("to") LocalDate to, Pageable pageable);
}
