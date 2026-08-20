package com.ferreplus.publico.service;

import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.model.EstadoPostulacion;
import java.util.Map;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class PostulacionStateMachine {
    private static final Map<EstadoPostulacion, Set<EstadoPostulacion>> TRANSITIONS = Map.of(
            EstadoPostulacion.RECEIVED, Set.of(EstadoPostulacion.UNDER_REVIEW),
            EstadoPostulacion.UNDER_REVIEW, Set.of(EstadoPostulacion.ACCEPTED, EstadoPostulacion.REJECTED),
            EstadoPostulacion.ACCEPTED, Set.of(), EstadoPostulacion.REJECTED, Set.of());

    public void validate(EstadoPostulacion from, EstadoPostulacion to) {
        if (!TRANSITIONS.getOrDefault(from, Set.of()).contains(to)) {
            throw new PublicApiException(HttpStatus.CONFLICT,
                    "Transicion invalida de " + from + " a " + to);
        }
    }
}
