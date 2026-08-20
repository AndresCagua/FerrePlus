package com.ferreplus.publico.service;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.assertThatCode;
import com.ferreplus.publico.model.EstadoPostulacion;
import org.junit.jupiter.api.Test;

class PostulacionStateMachineTest {
    private final PostulacionStateMachine machine = new PostulacionStateMachine();

    @Test void permiteFlujoCompletoAceptado() {
        assertThatCode(() -> machine.validate(EstadoPostulacion.RECEIVED, EstadoPostulacion.UNDER_REVIEW)).doesNotThrowAnyException();
        assertThatCode(() -> machine.validate(EstadoPostulacion.UNDER_REVIEW, EstadoPostulacion.ACCEPTED)).doesNotThrowAnyException();
    }
    @Test void rechazaReaperturaYEstadosTerminales() {
        assertThatThrownBy(() -> machine.validate(EstadoPostulacion.REJECTED, EstadoPostulacion.UNDER_REVIEW)).isInstanceOf(RuntimeException.class);
        assertThatThrownBy(() -> machine.validate(EstadoPostulacion.ACCEPTED, EstadoPostulacion.REJECTED)).isInstanceOf(RuntimeException.class);
        assertThatThrownBy(() -> machine.validate(EstadoPostulacion.RECEIVED, EstadoPostulacion.ACCEPTED)).isInstanceOf(RuntimeException.class);
    }
}
