package com.ferreplus.repository;

import com.ferreplus.entity.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductoRepository extends JpaRepository<Producto, Long> {

    List<Producto> findByCategoriaId(Long categoriaId);

    List<Producto> findByStockActualLessThanEqual(Integer stock);

    @Query("SELECT p FROM Producto p WHERE p.stockActual <= p.stockMinimo")
    List<Producto> findStockBajo();

    List<Producto> findByNombreContainingIgnoreCaseOrCodigoBarrasContainingIgnoreCase(String nombre, String codigoBarras);
}
