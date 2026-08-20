package com.ferreplus.publico.repository;

import com.ferreplus.publico.model.Destinatario;
import com.ferreplus.publico.model.TipoDestinatario;
import java.util.List;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface DestinatarioRepository extends MongoRepository<Destinatario, String> {
    List<Destinatario> findByTipoAndActivoTrue(TipoDestinatario tipo);
}
