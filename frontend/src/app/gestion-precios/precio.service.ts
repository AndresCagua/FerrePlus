import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { PrecioProducto, HistoricoPrecioProducto, ActualizarPrecioVentaRequest } from '../core/models';

@Injectable({ providedIn: 'root' })
export class PrecioService {
  private apiUrl = `${environment.apiUrl}/precios`;

  constructor(private http: HttpClient) {}

  list(): Observable<PrecioProducto[]> {
    return this.http.get<PrecioProducto[]>(this.apiUrl);
  }

  getById(id: number): Observable<PrecioProducto> {
    return this.http.get<PrecioProducto>(`${this.apiUrl}/${id}`);
  }

  getHistorial(id: number): Observable<HistoricoPrecioProducto[]> {
    return this.http.get<HistoricoPrecioProducto[]>(`${this.apiUrl}/${id}/historial`);
  }

  actualizarPrecioVenta(id: number, dto: ActualizarPrecioVentaRequest): Observable<PrecioProducto> {
    return this.http.put<PrecioProducto>(`${this.apiUrl}/${id}/venta`, dto);
  }
}