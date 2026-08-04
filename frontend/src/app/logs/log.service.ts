import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { AuditoriaLog, EliminarLogsResponse, Page } from '../core/models';

/** Filtros opcionales de `GET /api/logs` (R2/R7). */
export interface LogFiltros {
  fechaDesde?: string;
  fechaHasta?: string;
  usuarioId?: number | null;
  entidad?: string;
  accion?: string;
}

/** Opción de usuario para el dropdown del filtro (R7 refinamiento). */
export interface UsuarioOpcion {
  id: number;
  nombre: string;
}

/** Parámetros de listado: filtros + paginación server-side. */
export type LogListParams = LogFiltros & {
  page: number;
  size: number;
};

/**
 * Consulta y borrado de logs de auditoría (R2/R3/R7/R8).
 *
 * - `list` consume `GET /api/logs` paginado **server-side** (la tabla NO filtra
 *   client-side por volumen) y omite los filtros vacíos del query string.
 * - `deleteByRange` consume `DELETE /api/logs?desde=&hasta=` (bulk IRREVERSIBLE,
 *   solo tras confirmación del usuario en la UI).
 * - `listarUsuarios` consume `GET /api/logs/usuarios` para el selector del filtro.
 */
@Injectable({
  providedIn: 'root'
})
export class LogService {
  private apiUrl = `${environment.apiUrl}/logs`;

  constructor(private http: HttpClient) {}

  list(params: LogListParams): Observable<Page<AuditoriaLog>> {
    let httpParams = new HttpParams()
      .set('page', String(params.page))
      .set('size', String(params.size));

    for (const [clave, valor] of this.buildFiltros(params)) {
      httpParams = httpParams.set(clave, valor);
    }

    return this.http.get<Page<AuditoriaLog>>(this.apiUrl, { params: httpParams });
  }

  listarUsuarios(): Observable<UsuarioOpcion[]> {
    return this.http.get<UsuarioOpcion[]>(`${this.apiUrl}/usuarios`);
  }

  deleteByRange(desde: string, hasta: string): Observable<EliminarLogsResponse> {
    const httpParams = new HttpParams()
      .set('desde', desde)
      .set('hasta', hasta);
    return this.http.delete<EliminarLogsResponse>(this.apiUrl, { params: httpParams });
  }

  private buildFiltros(params: LogFiltros): Array<[string, string]> {
    const filtros: Array<[string, string]> = [];

    if (params.fechaDesde) {
      filtros.push(['fechaDesde', params.fechaDesde]);
    }
    if (params.fechaHasta) {
      filtros.push(['fechaHasta', params.fechaHasta]);
    }
    if (params.usuarioId != null) {
      filtros.push(['usuarioId', String(params.usuarioId)]);
    }
    if (params.entidad) {
      filtros.push(['entidad', params.entidad]);
    }
    if (params.accion) {
      filtros.push(['accion', params.accion]);
    }

    return filtros;
  }
}
