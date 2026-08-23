package com.ferreplus.publico.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

import com.ferreplus.publico.dto.interno.ConvocatoriaAdminDTO;
import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.model.EstadoConvocatoria;
import com.ferreplus.publico.repository.ConvocatoriaRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ConvocatoriaServiceTest {
    @Mock ConvocatoriaRepository repository;
    @InjectMocks ConvocatoriaService service;

    @Test
    void createPersistsJobFields() {
        ConvocatoriaAdminDTO dto = dto(Instant.parse("2026-08-20T10:00:00Z"), Instant.parse("2026-08-20T11:00:00Z"));
        when(repository.save(any(Convocatoria.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Convocatoria saved = service.crear(dto);

        assertThat(saved.getRequisitos()).containsExactly("Experiencia");
        assertThat(saved.getUbicacion()).isEqualTo("Bogota");
        assertThat(saved.getModalidad()).isEqualTo("Hibrida");
    }

    @Test
    void createRejectsInvalidDateRange() {
        ConvocatoriaAdminDTO dto = dto(Instant.parse("2026-08-20T11:00:00Z"), Instant.parse("2026-08-20T10:00:00Z"));

        assertThatThrownBy(() -> service.crear(dto)).hasMessage("La fecha de apertura debe ser anterior al cierre");
        verify(repository, never()).save(any());
    }

    @Test
    void findReturnsExistingConvocatoria() {
        Convocatoria convocatoria = new Convocatoria();
        convocatoria.setId("c-1");
        convocatoria.setTitulo("Convocatoria existente");
        when(repository.findById("c-1")).thenReturn(Optional.of(convocatoria));

        assertThat(service.find("c-1")).isSameAs(convocatoria);
    }

    @Test
    void findMissingConvocatoriaReturnsNotFound() {
        when(repository.findById("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.find("missing"))
                .isInstanceOf(com.ferreplus.publico.exception.PublicApiException.class)
                .hasMessage("Convocatoria no encontrada")
                .extracting("status")
                .isEqualTo(org.springframework.http.HttpStatus.NOT_FOUND);
    }

    private ConvocatoriaAdminDTO dto(Instant apertura, Instant cierre) {
        return new ConvocatoriaAdminDTO("Titulo", "Descripcion", List.of("Experiencia"), "Bogota", "Hibrida", apertura, cierre, EstadoConvocatoria.DRAFT);
    }
}
