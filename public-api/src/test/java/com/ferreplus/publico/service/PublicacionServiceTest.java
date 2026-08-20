package com.ferreplus.publico.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

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
}
