package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.model.EstadoConvocatoria;
import java.time.Instant;
import java.util.List;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface ConvocatoriaRepository extends MongoRepository<Convocatoria, String> {
    List<Convocatoria> findByEstado(EstadoConvocatoria estado);
    List<Convocatoria> findByEstadoAndFechaAperturaLessThanEqualAndFechaCierreGreaterThan(
            EstadoConvocatoria estado, Instant apertura, Instant cierre);
}
