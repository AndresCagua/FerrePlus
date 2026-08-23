package com.ferreplus.publico.controller;

import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.model.EstadoConvocatoria;
import com.ferreplus.publico.model.Contacto;
import com.ferreplus.publico.model.EstadoPostulacion;
import com.ferreplus.publico.model.EstadoPublicacion;
import com.ferreplus.publico.model.Destinatario;
import com.ferreplus.publico.model.ImagenMedia;
import com.ferreplus.publico.model.MetadataSEO;
import com.ferreplus.publico.model.Postulacion;
import com.ferreplus.publico.model.Publicacion;
import com.ferreplus.publico.model.TipoDestinatario;
import java.time.Instant;
import java.util.List;

final class InternalResponseMapper {
    private InternalResponseMapper() {}
    static ConvocatoriaResponse convocatoria(Convocatoria v) { return new ConvocatoriaResponse(v.getId(), v.getTitulo(), v.getDescripcion(), v.getRequisitos(), v.getUbicacion(), v.getModalidad(), v.getFechaApertura(), v.getFechaCierre(), v.getEstado(), v.getCreatedAt(), v.getUpdatedAt()); }
    static PublicacionResponse publicacion(Publicacion v) { return new PublicacionResponse(v.getId(), v.getSlug(), v.getTitulo(), v.getResumen(), v.getDescripcion(), v.getPortada(), v.getGaleria(), v.getVideoUrl(), v.getEnlacesX(), v.getCategoria(), v.getEstado(), v.getFechaPublicacion(), v.getFechaVencimiento(), v.getAutor(), v.getMetadataSEO(), v.getContenidoEnriquecido(), v.getCreatedAt(), v.getUpdatedAt()); }
    static PostulacionResponse postulacion(Postulacion v) { return new PostulacionResponse(v.getId(), v.getConvocatoriaId(), v.getNombres(), v.getApellidos(), v.getEmail(), v.getTelefono(), v.getCiudad(), v.getCv() == null ? null : v.getCv().fileName(), v.getCv() == null ? null : v.getCv().mimeType(), v.getCv() == null ? null : v.getCv().size(), v.getEstado(), v.getHistorial(), v.getCreatedAt(), v.getUpdatedAt()); }
    static ContactoResponse contacto(Contacto v) { return new ContactoResponse(v.getId(), v.getNombre(), v.getEmail(), v.getTelefono(), v.getAsunto(), v.getMensaje(), v.getEstado(), v.getCreatedAt(), v.getUpdatedAt()); }
    static DestinatarioResponse destinatario(Destinatario v) { return new DestinatarioResponse(v.getId(), v.getTipo(), v.getEmail(), v.isActivo()); }
    record ConvocatoriaResponse(String id, String titulo, String descripcion, List<String> requisitos, String ubicacion, String modalidad, Instant fechaApertura, Instant fechaCierre, EstadoConvocatoria estado, Instant createdAt, Instant updatedAt) {}
    record PublicacionResponse(String id, String slug, String titulo, String resumen, String descripcion, ImagenMedia portada, List<ImagenMedia> galeria, String videoUrl, List<String> enlacesX, String categoria, EstadoPublicacion estado, Instant fechaPublicacion, Instant fechaVencimiento, Publicacion.Autor autor, MetadataSEO metadataSEO, String contenidoEnriquecido, Instant createdAt, Instant updatedAt) {}
    record PostulacionResponse(String id, String convocatoriaId, String nombres, String apellidos, String email, String telefono, String ciudad, String cvFileName, String cvMimeType, Long cvSize, EstadoPostulacion estado, List<Postulacion.HistorialEstado> historial, Instant createdAt, Instant updatedAt) {}
    record ContactoResponse(String id, String nombre, String email, String telefono, String asunto, String mensaje, Contacto.EstadoContacto estado, Instant createdAt, Instant updatedAt) {}
    record DestinatarioResponse(String id, TipoDestinatario tipo, String email, boolean activo) {}
}
