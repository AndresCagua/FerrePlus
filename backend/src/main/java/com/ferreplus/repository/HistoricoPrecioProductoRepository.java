package com.ferreplus.repository;

import com.ferreplus.entity.HistoricoPrecioProducto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HistoricoPrecioProductoRepository extends JpaRepository<HistoricoPrecioProducto, Long> {

    List<HistoricoPrecioProducto> findByProductoIdOrderByFechaCambioDesc(Long productoId);

    List<HistoricoPrecioProducto> findByProductoIdOrderByFechaCambioAsc(Long productoId);
}
