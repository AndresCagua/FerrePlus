package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.EstadoPostulacion;
import com.ferreplus.publico.model.Postulacion;
import java.util.List;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface PostulacionRepository extends MongoRepository<Postulacion, String> {
    List<Postulacion> findByEstado(EstadoPostulacion estado);
    List<Postulacion> findByConvocatoriaId(String convocatoriaId);
    Optional<Postulacion> findByConvocatoriaIdAndIdempotencyKey(String convocatoriaId, String idempotencyKey);
}
