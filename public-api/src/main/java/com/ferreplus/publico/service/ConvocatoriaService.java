package com.ferreplus.publico.service;

import com.ferreplus.publico.dto.interno.ConvocatoriaAdminDTO;
import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.model.Convocatoria;
import com.ferreplus.publico.model.EstadoConvocatoria;
import com.ferreplus.publico.repository.ConvocatoriaRepository;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ConvocatoriaService {
    private final ConvocatoriaRepository repository;

    public List<Convocatoria> publicas() {
        Instant now = Instant.now();
        return repository.findByEstadoAndFechaAperturaLessThanEqualAndFechaCierreGreaterThan(
                EstadoConvocatoria.PUBLISHED, now, now);
    }
    public Convocatoria publica(String id) {
        Convocatoria convocatoria = find(id);
        if (!estaAbierta(convocatoria)) throw notFound();
        return convocatoria;
    }
    public boolean estaAbierta(Convocatoria convocatoria) {
        Instant now = Instant.now();
        return convocatoria.getEstado() == EstadoConvocatoria.PUBLISHED
                && !convocatoria.getFechaApertura().isAfter(now)
                && convocatoria.getFechaCierre().isAfter(now);
    }
    public List<Convocatoria> todas() { return repository.findAll(); }
    public Convocatoria find(String id) { return repository.findById(id).orElseThrow(this::notFound); }
    public Convocatoria crear(ConvocatoriaAdminDTO dto) { return repository.save(from(dto, new Convocatoria())); }
    public Convocatoria actualizar(String id, ConvocatoriaAdminDTO dto) {
        return repository.save(from(dto, find(id)));
    }
    public Convocatoria publicar(String id) { return changeState(id, EstadoConvocatoria.PUBLISHED); }
    public Convocatoria despublicar(String id) { return changeState(id, EstadoConvocatoria.DRAFT); }
    public Convocatoria cerrar(String id) { return changeState(id, EstadoConvocatoria.CLOSED); }
    public void eliminar(String id) { repository.delete(find(id)); }

    private Convocatoria changeState(String id, EstadoConvocatoria state) {
        Convocatoria item = find(id);
        item.setEstado(state); item.setUpdatedAt(Instant.now()); return repository.save(item);
    }
    private Convocatoria from(ConvocatoriaAdminDTO dto, Convocatoria item) {
        if (!dto.fechaApertura().isBefore(dto.fechaCierre()))
            throw new PublicApiException(HttpStatus.BAD_REQUEST, "La fecha de apertura debe ser anterior al cierre");
        item.setTitulo(dto.titulo()); item.setDescripcion(dto.descripcion());
        item.setFechaApertura(dto.fechaApertura()); item.setFechaCierre(dto.fechaCierre());
        item.setEstado(dto.estado()); item.setUpdatedAt(Instant.now());
        if (item.getCreatedAt() == null) item.setCreatedAt(Instant.now());
        return item;
    }
    private PublicApiException notFound() { return new PublicApiException(HttpStatus.NOT_FOUND, "Convocatoria no encontrada"); }
}
