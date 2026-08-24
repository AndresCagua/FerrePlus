package com.ferreplus.publico.service;

import com.ferreplus.publico.dto.interno.PublicacionAdminDTO;
import com.ferreplus.publico.dto.publico.PublicacionPublicaDTO;
import com.ferreplus.publico.dto.publico.MediaPublicaDTO;
import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.model.EstadoPublicacion;
import com.ferreplus.publico.model.Publicacion;
import com.ferreplus.publico.repository.PublicacionRepository;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import com.ferreplus.publico.storage.ImageFileValidator;
import com.ferreplus.publico.storage.MinioObjectStorage;
import java.io.IOException;
import java.util.ArrayList;
import java.net.URI;
import java.util.Locale;
import java.util.Objects;
import java.text.Normalizer;
import org.springframework.dao.DuplicateKeyException;

@Service
@RequiredArgsConstructor
public class PublicacionService {
    private static final int MAX_SLUG_LENGTH = 100;

    private final PublicacionRepository repository;
    private final ImageFileValidator imageValidator;
    private final MinioObjectStorage storage;

    public List<PublicacionPublicaDTO> publicas() {
        Instant now = Instant.now();
        return repository.findByEstado(EstadoPublicacion.PUBLISHED).stream().filter(this::vigente)
                .map(this::toPublic).toList();
    }

    public PublicacionPublicaDTO publica(String slug) {
        return repository.findBySlugAndEstado(slug, EstadoPublicacion.PUBLISHED)
                .filter(this::vigente).map(this::toPublic)
                .orElseThrow(() -> new PublicApiException(HttpStatus.NOT_FOUND, "Publicacion no encontrada"));
    }

    public List<Publicacion> todas() { return repository.findAll(); }

    public Publicacion crear(PublicacionAdminDTO dto) { return persist(from(dto, new Publicacion()), normalizarSlug(dto.titulo()), true); }
    public Publicacion crear(PublicacionAdminDTO dto, MultipartFile portada, List<MultipartFile> galeria) {
        Publicacion item = from(dto, new Publicacion());
        return saveMedia(item, portada, galeria, true);
    }

    public Publicacion actualizar(String id, PublicacionAdminDTO dto) {
        Publicacion existing = find(id);
        boolean titleChanged = !Objects.equals(existing.getTitulo(), dto.titulo());
        return persist(from(dto, existing), titleChanged ? normalizarSlug(dto.titulo()) : existing.getSlug(), titleChanged);
    }
    public Publicacion actualizar(String id, PublicacionAdminDTO dto, MultipartFile portada, List<MultipartFile> galeria) {
        Publicacion existing = find(id);
        var previousPortada = existing.getPortada();
        var previousGaleria = existing.getGaleria();
        boolean titleChanged = !Objects.equals(existing.getTitulo(), dto.titulo());
        Publicacion item = from(dto, existing);
        if ((portada == null || portada.isEmpty()) && dto.portada() == null) item.setPortada(previousPortada);
        if ((galeria == null || galeria.isEmpty()) && dto.galeria() == null) item.setGaleria(previousGaleria);
        return saveMedia(item, portada, galeria, titleChanged);
    }

    public Publicacion publicar(String id) { return changeState(id, EstadoPublicacion.PUBLISHED); }
    public Publicacion despublicar(String id) { return changeState(id, EstadoPublicacion.DRAFT); }

    public void eliminar(String id) { repository.delete(find(id)); }

    private Publicacion changeState(String id, EstadoPublicacion estado) {
        Publicacion item = find(id);
        item.setEstado(estado);
        if (estado == EstadoPublicacion.PUBLISHED && item.getFechaPublicacion() == null) item.setFechaPublicacion(Instant.now());
        item.setUpdatedAt(Instant.now());
        return repository.save(item);
    }

    private Publicacion from(PublicacionAdminDTO dto, Publicacion item) {
        if (dto.fechaVencimiento() != null && dto.fechaPublicacion() != null
                && !dto.fechaPublicacion().isBefore(dto.fechaVencimiento()))
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "La fecha de publicacion debe ser anterior al vencimiento");
        validateUrls(dto.videoUrl(), dto.enlacesX());
        item.setTitulo(dto.titulo()); item.setResumen(dto.resumen());
        item.setDescripcion(dto.descripcion()); item.setPortada(dto.portada()); item.setGaleria(dto.galeria());
        item.setVideoUrl(dto.videoUrl()); item.setEnlacesX(dto.enlacesX()); item.setCategoria(dto.categoria());
        item.setEstado(dto.estado()); item.setFechaPublicacion(dto.fechaPublicacion());
        item.setFechaVencimiento(dto.fechaVencimiento()); item.setMetadataSEO(dto.metadataSEO());
        item.setContenidoEnriquecido(dto.contenidoEnriquecido());
        Instant now = Instant.now(); if (item.getCreatedAt() == null) item.setCreatedAt(now); item.setUpdatedAt(now);
        return item;
    }

    public Publicacion find(String id) { return repository.findById(id).orElseThrow(() ->
            new PublicApiException(HttpStatus.NOT_FOUND, "Publicacion no encontrada")); }
    private boolean vigente(Publicacion item) {
        Instant now = Instant.now();
        return item.getFechaPublicacion() != null && !item.getFechaPublicacion().isAfter(now)
                && (item.getFechaVencimiento() == null || item.getFechaVencimiento().isAfter(now));
    }
    private Publicacion saveMedia(Publicacion item, MultipartFile portada, List<MultipartFile> gallery, boolean regenerateSlug) {
        List<String> uploaded = new ArrayList<>();
        try {
            if (portada != null && !portada.isEmpty()) item.setPortada(upload(item, portada, null, uploaded));
            if (gallery != null && !gallery.isEmpty()) {
                List<com.ferreplus.publico.model.ImagenMedia> images = new ArrayList<>();
                for (MultipartFile image : gallery) images.add(upload(item, image, null, uploaded));
                item.setGaleria(images);
            }
            return persist(item, normalizarSlug(item.getTitulo()), regenerateSlug);
        } catch (Exception exception) {
            uploaded.forEach(key -> { try { storage.delete(storage.mediaBucket(), key); } catch (Exception ignored) { } });
            if (exception instanceof com.ferreplus.publico.exception.PublicApiException api) throw api;
            throw new PublicApiException(HttpStatus.INTERNAL_SERVER_ERROR, "No fue posible almacenar las imagenes");
        }
    }

    private Publicacion persist(Publicacion item, String base, boolean regenerateSlug) {
        if (!regenerateSlug) return repository.save(item);
        for (int attempt = 1; attempt <= 5; attempt++) {
            item.setSlug(candidate(base, attempt));
            try {
                return repository.save(item);
            } catch (DuplicateKeyException collision) {
                if (attempt == 5) throw slugUnavailable();
            }
        }
        throw slugUnavailable();
    }

    private PublicApiException slugUnavailable() {
        return new PublicApiException(HttpStatus.CONFLICT, "El slug no esta disponible", "SLUG_UNAVAILABLE");
    }

    public static String normalizarSlug(String titulo) {
        String ascii = Normalizer.normalize(titulo == null ? "" : titulo, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT);
        String normalized = ascii.replaceAll("[^a-z0-9]+", "-").replaceAll("^-+|-+$", "");
        if (normalized.isBlank()) return "publicacion";
        StringBuilder result = new StringBuilder();
        for (String token : normalized.split("-")) {
            int extra = result.length() == 0 ? token.length() : token.length() + 1;
            if (result.length() + extra > MAX_SLUG_LENGTH) break;
            if (result.length() > 0) result.append('-');
            result.append(token);
        }
        if (result.length() > 0) return result.toString();

        // Un unico token puede superar el limite; en ese caso el corte es inevitable.
        return normalized.substring(0, Math.min(normalized.length(), MAX_SLUG_LENGTH));
    }

    private String candidate(String base, int attempt) {
        if (attempt == 1) return base;
        String suffix = "-" + attempt;
        String prefix = base.substring(0, Math.min(base.length(), MAX_SLUG_LENGTH - suffix.length())).replaceAll("-+$", "");
        return prefix + suffix;
    }
    private com.ferreplus.publico.model.ImagenMedia upload(Publicacion item, MultipartFile file, String alt, List<String> uploaded) throws IOException {
        var valid = imageValidator.validate(file); String key = java.util.UUID.randomUUID() + "." + valid.extension();
        storage.put(storage.mediaBucket(), key, file.getInputStream(), valid.size(), valid.mimeType()); uploaded.add(key);
        return new com.ferreplus.publico.model.ImagenMedia(key, alt == null ? valid.fileName() : alt);
    }
    private PublicacionPublicaDTO toPublic(Publicacion p) {
        return new PublicacionPublicaDTO(p.getId(), p.getSlug(), p.getTitulo(), p.getResumen(), p.getDescripcion(),
                publicMedia(p.getPortada()), p.getGaleria() == null ? List.of() : p.getGaleria().stream().map(this::publicMedia).toList(),
                p.getVideoUrl(), p.getEnlacesX(), p.getCategoria(),
                p.getFechaPublicacion(), p.getMetadataSEO());
    }

    private MediaPublicaDTO publicMedia(com.ferreplus.publico.model.ImagenMedia media) {
        if (media == null || media.objectKey() == null) return null;
        return new MediaPublicaDTO("/api/public/media/" + media.objectKey(), media.alt());
    }

    private void validateUrls(String videoUrl, List<String> enlacesX) {
        if (videoUrl != null && !videoUrl.isBlank() && !isAllowedUrl(videoUrl, "youtube.com", "youtu.be"))
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "El video debe ser una URL de YouTube valida", null,
                    Map.of("videoUrl", "El video debe ser una URL de YouTube valida"));
        if (enlacesX != null && enlacesX.stream().anyMatch(url -> url == null || !isAllowedUrl(url, "x.com", "twitter.com")))
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "El enlace de X no es valido. Usa una URL de x.com o twitter.com.", null,
                    Map.of("enlacesX", "El enlace de X no es valido. Usa una URL de x.com o twitter.com."));
    }

    private boolean isAllowedUrl(String value, String... hosts) {
        try {
            URI uri = URI.create(value.trim());
            String host = uri.getHost();
            if (!"https".equalsIgnoreCase(uri.getScheme()) || host == null) return false;
            String normalized = host.toLowerCase(Locale.ROOT);
            return java.util.Arrays.stream(hosts).anyMatch(allowed -> normalized.equals(allowed) || normalized.endsWith("." + allowed));
        } catch (IllegalArgumentException exception) { return false; }
    }
}
