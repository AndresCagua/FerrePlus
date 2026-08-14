package com.ferreplus.service.chat;

import com.ferreplus.dto.ProductoRankingDTO;
import com.ferreplus.entity.Auditoria;
import com.ferreplus.entity.Producto;
import com.ferreplus.repository.AuditoriaRepository;
import com.ferreplus.repository.ClienteRepository;
import com.ferreplus.repository.ProductoRepository;
import com.ferreplus.repository.ProveedorRepository;
import com.ferreplus.repository.UsuarioRepository;
import com.ferreplus.service.ReporteService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class AnalyticalChatService {
    private final ReporteService reporteService;
    private final AuditoriaRepository auditoriaRepository;
    private final ProductoRepository productoRepository;
    private final ClienteRepository clienteRepository;
    private final ProveedorRepository proveedorRepository;
    private final UsuarioRepository usuarioRepository;

    public AnalyticalChatService(
            ReporteService reporteService,
            AuditoriaRepository auditoriaRepository,
            ProductoRepository productoRepository,
            ClienteRepository clienteRepository,
            ProveedorRepository proveedorRepository,
            UsuarioRepository usuarioRepository) {
        this.reporteService = reporteService;
        this.auditoriaRepository = auditoriaRepository;
        this.productoRepository = productoRepository;
        this.clienteRepository = clienteRepository;
        this.proveedorRepository = proveedorRepository;
        this.usuarioRepository = usuarioRepository;
    }

    @Transactional(readOnly = true)
    public List<ProductoMasVendidoResult> productosMasVendidos(ValidatedChatParameters parameters) {
        return reporteService.getProductosMasVendidos(parameters.limit()).stream()
                .map(this::toProductoMasVendidoResult)
                .toList();
    }

    @Transactional(readOnly = true)
    public VentasMesResult ventasMes(ValidatedChatParameters parameters) {
        DateRange range = parameters.dateRange();
        return new VentasMesResult(range.from(), range.to(), reporteService.getVentasMes(range.from(), range.to()));
    }

    @Transactional(readOnly = true)
    public List<StockBajoResult> stockBajo(ValidatedChatParameters parameters) {
        return reporteService.getProductosStockBajo().stream()
                .limit(parameters.limit())
                .map(this::toStockBajoResult)
                .toList();
    }

    @Transactional(readOnly = true)
    public Optional<UltimoCambioResult> ultimoCambio(ChatEntity entity, Optional<String> entityName) {
        if (entity == null || entityName == null) {
            return Optional.empty();
        }
        if (entityName.isPresent() && !supportsNameResolution(entity)) {
            return Optional.empty();
        }

        String entityToken = entity.name();
        Optional<Auditoria> audit = entityName
                .map(name -> resolveEntityId(entity, name)
                        .flatMap(id -> auditoriaRepository
                                .findFirstByEntidadAndEntidadIdOrderByFechaDescIdDesc(entityToken, id)))
                .orElseGet(() -> auditoriaRepository.findFirstByEntidadOrderByFechaDescIdDesc(entityToken));
        return audit.map(this::toUltimoCambioResult);
    }

    private Optional<Long> resolveEntityId(ChatEntity entity, String name) {
        return switch (entity) {
            case PRODUCTO -> productoRepository.findFirstByNombreIgnoreCaseOrderByIdAsc(name).map(Producto::getId);
            case CLIENTE -> clienteRepository.findFirstByNombreIgnoreCaseOrderByIdAsc(name).map(value -> value.getId());
            case PROVEEDOR -> proveedorRepository.findFirstByNombreIgnoreCaseOrderByIdAsc(name).map(value -> value.getId());
            case USUARIO -> usuarioRepository.findFirstByNombreIgnoreCaseOrderByIdAsc(name).map(value -> value.getId());
            case VENTA, COMPRA, GASTO -> Optional.empty();
        };
    }

    private boolean supportsNameResolution(ChatEntity entity) {
        return switch (entity) {
            case PRODUCTO, CLIENTE, PROVEEDOR, USUARIO -> true;
            case VENTA, COMPRA, GASTO -> false;
        };
    }

    private ProductoMasVendidoResult toProductoMasVendidoResult(ProductoRankingDTO ranking) {
        return new ProductoMasVendidoResult(ranking.getProductoId(), ranking.getNombre(), ranking.getTotalVendido());
    }

    private StockBajoResult toStockBajoResult(Producto producto) {
        return new StockBajoResult(
                producto.getId(), producto.getNombre(), producto.getStockActual(), producto.getStockMinimo());
    }

    private UltimoCambioResult toUltimoCambioResult(Auditoria audit) {
        String userName = audit.getUsuario() == null ? null : audit.getUsuario().getNombre();
        return new UltimoCambioResult(
                audit.getEntidad(), audit.getEntidadId(), audit.getAccion(), audit.getFecha(), userName, audit.getDetalle());
    }
}
