import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../environments/environment';
import { DashboardData, Producto } from '../core/models';

interface ReporteDTO {
  totalProductos: number;
  productosStockBajo: number;
  ventasHoy: number;
  totalVentasHoy: number;
  ventasMes: number;
  totalVentasMes: number;
  comprasMes: number;
  totalComprasMes: number;
  gastosMes: number;
  totalGastosMes: number;
  totalClientes: number;
  totalProveedores: number;
  totalUsuarios: number;
  saldoPendienteClientes: number;
}

@Injectable({
  providedIn: 'root'
})
export class DashboardService {
  private apiUrl = `${environment.apiUrl}/reportes`;

  constructor(private http: HttpClient) {}

  getDashboardData(): Observable<DashboardData> {
    return this.http.get<ReporteDTO>(`${this.apiUrl}/dashboard`).pipe(
      map(reporte => ({
        totalProductos: Number(reporte.totalProductos),
        productosStockBajo: Number(reporte.productosStockBajo),
        ventasHoy: Number(reporte.ventasHoy),
        totalVentasHoy: Number(reporte.totalVentasHoy),
        ventasMes: Number(reporte.ventasMes),
        totalVentasMes: Number(reporte.totalVentasMes),
        comprasMes: Number(reporte.comprasMes),
        totalComprasMes: Number(reporte.totalComprasMes),
        gastosMes: Number(reporte.gastosMes),
        totalGastosMes: Number(reporte.totalGastosMes),
        totalClientes: Number(reporte.totalClientes),
        totalProveedores: Number(reporte.totalProveedores),
        totalUsuarios: Number(reporte.totalUsuarios),
        saldoPendienteClientes: Number(reporte.saldoPendienteClientes)
      }))
    );
  }

  getVentasPorDia(desde: string, hasta: string): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/ventas`, {
      params: { desde, hasta }
    });
  }
}
