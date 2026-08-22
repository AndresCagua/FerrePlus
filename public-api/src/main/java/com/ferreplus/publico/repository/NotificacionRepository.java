package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.EstadoNotificacion;
import com.ferreplus.publico.model.Notificacion;
import java.util.List;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.time.Instant;

public interface NotificacionRepository extends MongoRepository<Notificacion, String> {
    List<Notificacion> findByEstado(EstadoNotificacion estado);
    List<Notificacion> findTop20ByEstadoInAndNextAttemptAtLessThanEqualOrderByNextAttemptAtAsc(
            List<EstadoNotificacion> estados, Instant now);
    List<Notificacion> findTop20ByEstadoInAndNextAttemptAtIsNullOrderByCreatedAtAsc(List<EstadoNotificacion> estados);
}
