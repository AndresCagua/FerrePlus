import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Venta } from '../core/models';

@Injectable({
  providedIn: 'root'
})
export class VentaService {
  private apiUrl = `${environment.apiUrl}/ventas`;

  constructor(private http: HttpClient) {}

  list(): Observable<Venta[]> {
    return this.http.get<Venta[]>(this.apiUrl);
  }

  getById(id: number): Observable<Venta> {
    return this.http.get<Venta>(`${this.apiUrl}/${id}`);
  }

  create(venta: any): Observable<Venta> {
    return this.http.post<Venta>(this.apiUrl, venta);
  }

  anular(id: number): Observable<void> {
    return this.http.put<void>(`${this.apiUrl}/${id}/anular`, {});
  }

  listByFecha(desde: string, hasta: string): Observable<Venta[]> {
    const params = new HttpParams()
      .set('desde', desde)
      .set('hasta', hasta);
    return this.http.get<Venta[]>(`${this.apiUrl}/reportes/por-fecha`, { params });
  }
}
