import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Compra } from '../core/models';

@Injectable({
  providedIn: 'root'
})
export class CompraService {
  private apiUrl = `${environment.apiUrl}/compras`;

  constructor(private http: HttpClient) {}

  list(): Observable<Compra[]> {
    return this.http.get<Compra[]>(this.apiUrl);
  }

  getById(id: number): Observable<Compra> {
    return this.http.get<Compra>(`${this.apiUrl}/${id}`);
  }

  create(compra: any): Observable<Compra> {
    return this.http.post<Compra>(this.apiUrl, compra);
  }

  update(id: number, data: any): Observable<Compra> {
    return this.http.put<Compra>(`${this.apiUrl}/${id}`, data);
  }

  anular(id: number): Observable<void> {
    return this.http.put<void>(`${this.apiUrl}/${id}/anular`, {});
  }

  listByFecha(desde: string, hasta: string): Observable<Compra[]> {
    const params = new HttpParams()
      .set('desde', desde)
      .set('hasta', hasta);
    return this.http.get<Compra[]>(`${this.apiUrl}/reportes/por-fecha`, { params });
  }
}
