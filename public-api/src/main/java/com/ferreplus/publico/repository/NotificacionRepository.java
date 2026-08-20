package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.EstadoNotificacion;
import com.ferreplus.publico.model.Notificacion;
import java.util.List;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface NotificacionRepository extends MongoRepository<Notificacion, String> {
    List<Notificacion> findByEstado(EstadoNotificacion estado);
}
