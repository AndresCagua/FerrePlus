package com.ferreplus.publico.dto.publico;

import com.ferreplus.publico.model.MetadataSEO;
import java.time.Instant;
import java.util.List;

public record PublicacionPublicaDTO(String id, String slug, String titulo, String resumen,
        String descripcion, MediaPublicaDTO portada, List<MediaPublicaDTO> galeria, String videoUrl,
        List<String> enlacesX, String categoria, Instant fechaPublicacion, MetadataSEO metadataSEO) {}
