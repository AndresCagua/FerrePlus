package com.ferreplus.service;

import com.ferreplus.dto.AuditoriaDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Usuario;
import com.ferreplus.exception.BadRequestException;
import com.ferreplus.repository.AuditoriaRepository;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Expression;
import jakarta.persistence.criteria.Path;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Contrato de {@link LogService} (R2/R3, D4): construcción de {@link Specification}
 * con filtros opcionales, mapeo a {@link AuditoriaDTO} (usuario nullable) y
 * validación del rango de borrado (400 por ausencia/formato/revertido).
 */
@ExtendWith(MockitoExtension.class)
class LogServiceTest {

    @Mock
    private AuditoriaRepository auditoriaRepository;

    @InjectMocks
    private LogService logService;

    @Captor
    private ArgumentCaptor<Specification<Auditoria>> specCaptor;

    private final Pageable pageable = PageRequest.of(0, 20);

    @Test
    void consultar_conTodosLosFiltros_pasaSpecification() {
        when(auditoriaRepository.findAll(any(Specification.class), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of()));

        logService.consultar("2026-01-01", "2026-01-31T23:59:59", 7L, "venta", "crear", null, pageable);

        verify(auditoriaRepository).findAll(specCaptor.capture(), eq(pageable));
        assertNotNull(specCaptor.getValue(), "El servicio debe pasar una Specification construida");
    }

    @Test
    void consultar_sinFiltros_pasaSpecificationSinPredicados() {
        when(auditoriaRepository.findAll(any(Specification.class), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of()));

        logService.consultar(null, null, null, null, null, null, pageable);

        verify(auditoriaRepository).findAll(specCaptor.capture(), eq(pageable));
        assertNotNull(specCaptor.getValue(), "Sin filtros se pasa Specification.where(null) (no null literal)");
    }

    @Test
    void consultar_conUsuarioNombre_construyePredicadoContainsCaseInsensitive() {
        when(auditoriaRepository.findAll(any(Specification.class), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of()));

        logService.consultar(null, null, null, null, null, "aNa", pageable);

        verify(auditoriaRepository).findAll(specCaptor.capture(), eq(pageable));

        Root<Auditoria> root = mock(Root.class);
        CriteriaQuery<?> query = mock(CriteriaQuery.class);
        CriteriaBuilder cb = mock(CriteriaBuilder.class);
        Path<Object> usuarioPath = mock(Path.class);
        Path<Object> nombrePath = mock(Path.class);
        Expression<String> nombreLower = mock(Expression.class);
        Predicate predicate = mock(Predicate.class);

        when(root.get("usuario")).thenReturn(usuarioPath);
        when(usuarioPath.get("nombre")).thenReturn(nombrePath);
        when(nombrePath.as(String.class)).thenReturn(nombreLower);
        when(cb.lower(any(Expression.class))).thenReturn(nombreLower);
        when(cb.like(any(Expression.class), anyString())).thenReturn(predicate);

        specCaptor.getValue().toPredicate(root, query, cb);

        // LIKE %valor% sobre usuario.nombre, case-insensitive (lower en ambos lados)
        verify(cb).like(eq(nombreLower), eq("%ana%"));
    }

    @Test
    void consultar_usuarioNombreNullVacioOBlanco_noAgregaPredicado() {
        when(auditoriaRepository.findAll(any(Specification.class), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of()));

        logService.consultar(null, null, null, null, null, null, pageable);
        logService.consultar(null, null, null, null, null, "", pageable);
        logService.consultar(null, null, null, null, null, "   ", pageable);

        verify(auditoriaRepository, times(3)).findAll(specCaptor.capture(), eq(pageable));

        Root<Auditoria> root = mock(Root.class);
        CriteriaQuery<?> query = mock(CriteriaQuery.class);
        CriteriaBuilder cb = mock(CriteriaBuilder.class);

        for (Specification<Auditoria> spec : specCaptor.getAllValues()) {
            spec.toPredicate(root, query, cb);
        }

        verify(cb, never()).like(any(), anyString());
        verify(cb, never()).lower(any());
    }

    @Test
    void consultar_conUsuarioIdYUsuarioNombre_losCombinaEnElMismoSpec() {
        when(auditoriaRepository.findAll(any(Specification.class), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of()));

        logService.consultar(null, null, 7L, null, null, "ana", pageable);

        verify(auditoriaRepository).findAll(specCaptor.capture(), eq(pageable));

        Root<Auditoria> root = mock(Root.class);
        CriteriaQuery<?> query = mock(CriteriaQuery.class);
        CriteriaBuilder cb = mock(CriteriaBuilder.class);
        Path<Object> usuarioPath = mock(Path.class);
        Path<Object> idPath = mock(Path.class);
        Path<Object> nombrePath = mock(Path.class);
        Expression<String> nombreLower = mock(Expression.class);
        Predicate pId = mock(Predicate.class);
        Predicate pLike = mock(Predicate.class);

        when(root.get("usuario")).thenReturn(usuarioPath);
        when(usuarioPath.get("id")).thenReturn(idPath);
        when(usuarioPath.get("nombre")).thenReturn(nombrePath);
        when(nombrePath.as(String.class)).thenReturn(nombreLower);
        when(cb.equal(idPath, 7L)).thenReturn(pId);
        when(cb.lower(any(Expression.class))).thenReturn(nombreLower);
        when(cb.like(any(Expression.class), anyString())).thenReturn(pLike);

        specCaptor.getValue().toPredicate(root, query, cb);

        verify(cb).equal(idPath, 7L);
        verify(cb).like(eq(nombreLower), eq("%ana%"));
    }

    @Test
    void consultar_conUsuarioNombre_mapeaUsuarioIdYNombre() {
        Usuario usuario = Usuario.builder().id(7L).nombre("Ana García").build();
        Auditoria auditoria = Auditoria.builder()
                .id(1L)
                .entidad("VENTA")
                .entidadId(10L)
                .accion("CREAR")
                .fecha(LocalDateTime.of(2026, 1, 10, 10, 0))
                .detalle("{\"total\":150.00}")
                .build();
        auditoria.setUsuario(usuario);

        when(auditoriaRepository.findAll(any(Specification.class), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of(auditoria)));

        Page<AuditoriaDTO> resultado = logService.consultar(null, null, null, null, null, null, pageable);

        AuditoriaDTO dto = resultado.getContent().get(0);
        assertEquals(1L, dto.getId());
        assertEquals("VENTA", dto.getEntidad());
        assertEquals(10L, dto.getEntidadId());
        assertEquals("CREAR", dto.getAccion());
        assertEquals(7L, dto.getUsuarioId(), "Con usuario, usuarioId debe mapearse");
        assertEquals("Ana García", dto.getUsuarioNombre(), "Con usuario, usuarioNombre debe mapearse");
        assertEquals("{\"total\":150.00}", dto.getDetalle(), "El detalle se expone tal cual (JSON crudo)");
    }

    @Test
    void consultar_sinUsuario_dejaUsuarioIdYNombreNulos() {
        Auditoria auditoria = Auditoria.builder()
                .id(2L)
                .entidad("PRODUCTO")
                .entidadId(5L)
                .accion("CREAR")
                .fecha(LocalDateTime.of(2026, 1, 15, 12, 0))
                .build();

        when(auditoriaRepository.findAll(any(Specification.class), eq(pageable)))
                .thenReturn(new PageImpl<>(List.of(auditoria)));

        Page<AuditoriaDTO> resultado = logService.consultar(null, null, null, null, null, null, pageable);

        AuditoriaDTO dto = resultado.getContent().get(0);
        assertNull(dto.getUsuarioId(), "Evento de sistema: usuarioId debe quedar null");
        assertNull(dto.getUsuarioNombre(), "Evento de sistema: usuarioNombre debe quedar null");
    }

    @Test
    void eliminarPorRango_fechaSola_expandeInicioYFinDeDia() {
        when(auditoriaRepository.borrarPorRango(any(), any())).thenReturn(3);

        int eliminados = logService.eliminarPorRango("2026-01-01", "2026-01-31");

        LocalDateTime desde = LocalDate.parse("2026-01-01").atStartOfDay();
        LocalDateTime hasta = LocalDate.parse("2026-01-31").atTime(LocalTime.MAX);
        verify(auditoriaRepository).borrarPorRango(desde, hasta);
        assertEquals(3, eliminados);
    }

    @Test
    void eliminarPorRango_datetimeISO_usaElValorLiteral() {
        when(auditoriaRepository.borrarPorRango(any(), any())).thenReturn(0);

        LocalDateTime desde = LocalDateTime.parse("2026-01-01T08:30:00");
        LocalDateTime hasta = LocalDateTime.parse("2026-01-31T17:45:00");
        logService.eliminarPorRango("2026-01-01T08:30:00", "2026-01-31T17:45:00");

        verify(auditoriaRepository).borrarPorRango(desde, hasta);
    }

    @Test
    void eliminarPorRango_sinRango_lanza400YNoBorra() {
        assertThrows(BadRequestException.class, () -> logService.eliminarPorRango(null, "2026-01-31"));
        assertThrows(BadRequestException.class, () -> logService.eliminarPorRango("2026-01-01", null));
        assertThrows(BadRequestException.class, () -> logService.eliminarPorRango("", "2026-01-31"));

        verify(auditoriaRepository, never()).borrarPorRango(any(), any());
    }

    @Test
    void eliminarPorRango_formatoInvalido_lanza400YNoBorra() {
        assertThrows(BadRequestException.class, () -> logService.eliminarPorRango("abc", "2026-01-31"));

        verify(auditoriaRepository, never()).borrarPorRango(any(), any());
    }

    @Test
    void eliminarPorRango_rangoInvertido_lanza400YNoBorra() {
        assertThrows(BadRequestException.class,
                () -> logService.eliminarPorRango("2026-02-01", "2026-01-01"));

        verify(auditoriaRepository, never()).borrarPorRango(any(), any());
    }
}
