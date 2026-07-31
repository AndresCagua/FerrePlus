import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Rol, RolRequest } from '../core/models';

/**
 * CRUD de roles con matriz de permisos (R3).
 * Lecturas: `ROLES_VER`; escrituras: `ROLES_EDITAR` (enforced en backend).
 */
@Injectable({
  providedIn: 'root'
})
export class RolService {
  private apiUrl = `${environment.apiUrl}/roles`;

  constructor(private http: HttpClient) {}

  list(): Observable<Rol[]> {
    return this.http.get<Rol[]>(this.apiUrl);
  }

  getById(id: number): Observable<Rol> {
    return this.http.get<Rol>(`${this.apiUrl}/${id}`);
  }

  create(dto: RolRequest): Observable<Rol> {
    return this.http.post<Rol>(this.apiUrl, dto);
  }

  update(id: number, dto: RolRequest): Observable<Rol> {
    return this.http.put<Rol>(`${this.apiUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
