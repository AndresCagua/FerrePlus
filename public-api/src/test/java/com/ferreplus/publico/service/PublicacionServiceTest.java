package com.ferreplus.publico.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.ferreplus.publico.dto.interno.PublicacionAdminDTO;
import com.ferreplus.publico.model.EstadoPublicacion;
import com.ferreplus.publico.model.Publicacion;
import com.ferreplus.publico.repository.PublicacionRepository;
import java.util.List;
import java.util.Collections;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DuplicateKeyException;

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

    @Test
    void rejectsVideoOutsideYoutube() {
        var request = new PublicacionAdminDTO("Titulo", "Resumen", "Descripcion", null, null,
                "https://example.com/video", Collections.emptyList(), null, EstadoPublicacion.DRAFT,
                null, null, null, null);
        assertThatThrownBy(() -> service.crear(request))
                .isInstanceOf(com.ferreplus.publico.exception.PublicApiException.class)
                .hasMessage("El video debe ser una URL de YouTube valida");
        verifyNoInteractions(repository);
    }

    @Test
    void rejectsFacebookSocialLinkOutsideX() {
        var request = new PublicacionAdminDTO("Titulo", "Resumen", "Descripcion", null, null,
                null, List.of("https://facebook.com/ferreplus"), null, EstadoPublicacion.DRAFT,
                null, null, null, null);

        assertThatThrownBy(() -> service.crear(request))
                .isInstanceOf(com.ferreplus.publico.exception.PublicApiException.class)
                .hasMessage("El enlace de X no es valido. Usa una URL de x.com o twitter.com.");
        verifyNoInteractions(repository);
    }

    @Test
    void acceptsXAndTwitterLinks() {
        var request = new PublicacionAdminDTO("Titulo", "Resumen", "Descripcion", null, null,
                null, List.of("https://x.com/ferreplus", "https://twitter.com/ferreplus"), null,
                EstadoPublicacion.DRAFT, null, null, null, null);
        when(repository.save(any(Publicacion.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(service.crear(request).getEnlacesX()).containsExactlyElementsOf(request.enlacesX());
    }

    @Test
    void normalizesAccentsAndFallsBackForSymbols() {
        assertThat(PublicacionService.normalizarSlug("Talento: Niño Técnico / Bogotá"))
                .isEqualTo("talento-nino-tecnico-bogota");
        assertThat(PublicacionService.normalizarSlug("***" )).isEqualTo("publicacion");
    }

    @Test
    void limitsSlugTo100CharactersWithoutExtremeHyphens() {
        String longToken = "a".repeat(120);

        assertThat(PublicacionService.normalizarSlug(longToken))
                .hasSize(100)
                .doesNotStartWith("-")
                .doesNotEndWith("-");
    }

    @Test
    void keepsCompleteTokensWhenTheNextTokenWouldExceedLimit() {
        String title = "a".repeat(96) + " segundo-token";

        assertThat(PublicacionService.normalizarSlug(title))
                .isEqualTo("a".repeat(96));
    }

    @Test
    void backendIgnoresClientSlugAndReturnsGeneratedSlug() {
        var request = new PublicacionAdminDTO("Talento Niño", "Resumen", "Descripcion", null, null,
                null, List.of(), null, EstadoPublicacion.DRAFT, null, null, null, null);
        when(repository.save(any(Publicacion.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(service.crear(request).getSlug()).isEqualTo("talento-nino");
    }

    @Test
    void retriesDeterministicCandidateAfterCollision() {
        var request = new PublicacionAdminDTO("Talento Niño", "Resumen", "Descripcion", null, null,
                null, List.of(), null, EstadoPublicacion.DRAFT, null, null, null, null);
        when(repository.save(any(Publicacion.class)))
                .thenThrow(new DuplicateKeyException("duplicate"))
                .thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(service.crear(request).getSlug()).isEqualTo("talento-nino-2");
    }

    @Test
    void exhaustedSlugCandidatesReturnConflictWithoutPartialSave() {
        var request = new PublicacionAdminDTO("Talento Niño", "Resumen", "Descripcion", null, null,
                null, List.of(), null, EstadoPublicacion.DRAFT, null, null, null, null);
        when(repository.save(any(Publicacion.class)))
                .thenThrow(new DuplicateKeyException("duplicate"));

        assertThatThrownBy(() -> service.crear(request))
                .isInstanceOf(com.ferreplus.publico.exception.PublicApiException.class)
                .hasMessage("El slug no esta disponible")
                .extracting("status")
                .isEqualTo(org.springframework.http.HttpStatus.CONFLICT);
        verify(repository, times(5)).save(any(Publicacion.class));
    }

    @Test
    void recalculatesSlugWhenTitleChanges() {
        Publicacion existing = new Publicacion();
        existing.setId("1");
        existing.setTitulo("Titulo anterior");
        existing.setSlug("titulo-anterior");
        when(repository.findById("1")).thenReturn(java.util.Optional.of(existing));
        when(repository.save(existing)).thenReturn(existing);
        var request = new PublicacionAdminDTO("Titulo nuevo", "Resumen", "Descripcion", null, null,
                null, List.of(), null, EstadoPublicacion.DRAFT, null, null, null, null);

        assertThat(service.actualizar("1", request).getSlug()).isEqualTo("titulo-nuevo");
    }

    @Test
    void preservesSlugWhenTitleDoesNotChange() {
        Publicacion existing = new Publicacion();
        existing.setId("1"); existing.setTitulo("Titulo"); existing.setSlug("slug-final");
        when(repository.findById("1")).thenReturn(java.util.Optional.of(existing));
        when(repository.save(existing)).thenReturn(existing);
        var request = new PublicacionAdminDTO("Titulo", "Resumen", "Descripcion", null, null,
                null, List.of(), null, EstadoPublicacion.DRAFT, null, null, null, null);

        assertThat(service.actualizar("1", request).getSlug()).isEqualTo("slug-final");
        verify(repository).save(existing);
    }
}
