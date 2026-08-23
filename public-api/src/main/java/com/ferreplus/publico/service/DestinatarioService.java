package com.ferreplus.publico.service;

import com.ferreplus.publico.dto.interno.DestinatarioDTO;
import com.ferreplus.publico.exception.PublicApiException;
import com.ferreplus.publico.model.Destinatario;
import com.ferreplus.publico.model.TipoDestinatario;
import com.ferreplus.publico.repository.DestinatarioRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DestinatarioService {
    private final DestinatarioRepository repository;
    public List<Destinatario> all() { return repository.findAll(); }
    public Destinatario create(DestinatarioDTO dto) { return repository.save(from(dto, new Destinatario())); }
    public Destinatario update(String id, DestinatarioDTO dto) {
        Destinatario item = repository.findById(id).orElseThrow(() -> notFound());
        return repository.save(from(dto, item));
    }
    public void delete(String id) { repository.delete(repository.findById(id).orElseThrow(() -> notFound())); }
    public List<Destinatario> active(TipoDestinatario type) { return repository.findByTipoAndActivoTrue(type); }
    private Destinatario from(DestinatarioDTO dto, Destinatario item) {
        item.setTipo(dto.tipo()); item.setEmail(dto.email().trim().toLowerCase()); item.setActivo(dto.activo()); return item;
    }
    private PublicApiException notFound() { return new PublicApiException(HttpStatus.NOT_FOUND, "Destinatario no encontrado"); }
}
