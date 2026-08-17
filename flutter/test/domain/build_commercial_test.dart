import 'package:flutter_test/flutter_test.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';
import 'package:ferreplus/domain/use_cases/build_purchase.dart';
import 'package:ferreplus/domain/use_cases/build_sale.dart';

void main() {
  test('BuildSale calculates subtotal, 15 percent IVA and total', () {
    final VentaRequest request = const BuildSale().call(
      detalles: <DetalleVenta>[
        const DetalleVenta(productoId: 1, cantidad: 2, precioUnitario: 100),
        const DetalleVenta(productoId: 2, cantidad: 1, precioUnitario: 50),
      ],
    );
    expect(request.subtotal, 250);
    expect(request.iva, 37.5);
    expect(request.total, 287.5);
  });

  test('BuildSale rejects insufficient stock and empty details', () {
    expect(
      () => const BuildSale().call(detalles: <DetalleVenta>[]),
      throwsArgumentError,
    );
    expect(
      () => const BuildSale().call(
        detalles: <DetalleVenta>[
          const DetalleVenta(productoId: 1, cantidad: 3, precioUnitario: 1),
        ],
        stockByProduct: <int, int>{1: 1},
      ),
      throwsArgumentError,
    );
  });

  test('BuildPurchase validates invoice and calculates total', () {
    final CompraRequest request = const BuildPurchase().call(
      numeroFactura: 'F-1',
      detalles: <DetalleCompra>[
        const DetalleCompra(productoId: 4, cantidad: 2, precioUnitario: 10),
      ],
    );
    expect(request.subtotal, 20);
    expect(request.total, 23);
    expect(
      () => const BuildPurchase().call(
        numeroFactura: '',
        detalles: <DetalleCompra>[],
      ),
      throwsArgumentError,
    );
  });
}
