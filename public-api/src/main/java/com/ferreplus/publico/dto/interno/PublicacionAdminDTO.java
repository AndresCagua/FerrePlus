package com.ferreplus.publico.dto.interno;

import com.ferreplus.publico.model.EstadoPublicacion;
import com.ferreplus.publico.model.ImagenMedia;
import com.ferreplus.publico.model.MetadataSEO;
import java.time.Instant;
import java.util.List;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PublicacionAdminDTO(@NotBlank String titulo, @NotBlank String slug,
        String resumen, String descripcion, ImagenMedia portada, List<ImagenMedia> galeria,
        String videoUrl, List<String> enlacesX, String categoria, @NotNull EstadoPublicacion estado,
        Instant fechaPublicacion, Instant fechaVencimiento, MetadataSEO metadataSEO,
        String contenidoEnriquecido) {}
