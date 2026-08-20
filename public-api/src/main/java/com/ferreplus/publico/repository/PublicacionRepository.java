package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.EstadoPublicacion;
import com.ferreplus.publico.model.Publicacion;
import java.util.List;
import java.util.Optional;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface PublicacionRepository extends MongoRepository<Publicacion, String> {
    List<Publicacion> findByEstado(EstadoPublicacion estado);
    Optional<Publicacion> findBySlugAndEstado(String slug, EstadoPublicacion estado);
}
