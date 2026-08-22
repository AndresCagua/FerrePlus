package com.ferreplus.publico.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.ferreplus.publico.dto.interno.PublicacionAdminDTO;
import com.ferreplus.publico.model.EstadoPublicacion;
import com.ferreplus.publico.model.Publicacion;
import com.ferreplus.publico.repository.PublicacionRepository;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PublicacionServiceTest {
    @Mock PublicacionRepository repository;
    @InjectMocks PublicacionService service;

    @Test
    void draftIsNotReturnedInPublicListing() {
        Publicacion draft = new Publicacion(); draft.setEstado(EstadoPublicacion.DRAFT);
        when(repository.findByEstado(EstadoPublicacion.PUBLISHED)).thenReturn(List.of());
        assertThat(service.publicas()).isEmpty();
        verify(repository).findByEstado(EstadoPublicacion.PUBLISHED);
    }

    @Test
    void publishingAddsPublicationDateWhenMissing() {
        Publicacion draft = new Publicacion(); draft.setEstado(EstadoPublicacion.DRAFT);
        when(repository.findById("1")).thenReturn(java.util.Optional.of(draft));
        when(repository.save(draft)).thenReturn(draft);
        assertThat(service.publicar("1").getEstado()).isEqualTo(EstadoPublicacion.PUBLISHED);
        assertThat(draft.getFechaPublicacion()).isNotNull();
    }

    @Test
    void findReturnsInternalPublicationById() {
        Publicacion publication = new Publicacion();
        publication.setId("publication-1");
        when(repository.findById("publication-1")).thenReturn(java.util.Optional.of(publication));

        assertThat(service.find("publication-1")).isSameAs(publication);
    }

    @Test
    void findMissingPublicationReturnsNotFoundDomainError() {
        when(repository.findById("missing")).thenReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> service.find("missing"))
                .isInstanceOf(com.ferreplus.publico.exception.PublicApiException.class)
                .hasMessage("Publicacion no encontrada")
                .extracting("status")
                .isEqualTo(org.springframework.http.HttpStatus.NOT_FOUND);
    }
}
