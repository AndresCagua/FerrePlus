import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { timeout } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { Publicacion, PublicacionPayload } from '../models/publicacion';
import { Convocatoria, ConvocatoriaPayload } from '../models/convocatoria';
import { Postulacion, PostulacionEstado } from '../models/postulacion';
import { Contacto } from '../models/contacto';
import { Destinatario, DestinatarioPayload } from '../models/destinatario';

@Injectable({ providedIn: 'root' })
export class TalentoService {
  private readonly baseUrl = `${environment.apiUrl}/admin/talento`;
  private readonly requestTimeoutMs = 5000;

  constructor(private readonly http: HttpClient) {}

  private request<T>(source: Observable<T>): Observable<T> {
    return source.pipe(timeout({ each: this.requestTimeoutMs }));
  }

  listarPublicaciones(): Observable<Publicacion[]> { return this.request(this.http.get<Publicacion[]>(`${this.baseUrl}/publicaciones`)); }
  obtenerPublicacion(id: string): Observable<Publicacion> { return this.request(this.http.get<Publicacion>(`${this.baseUrl}/publicaciones/${id}`)); }
  crearPublicacion(payload: PublicacionPayload, portada?: File, galeria: File[] = []): Observable<Publicacion> {
    return this.request(this.http.post<Publicacion>(`${this.baseUrl}/publicaciones`, this.multipart(payload, portada, galeria)));
  }
  actualizarPublicacion(id: string, payload: PublicacionPayload, portada?: File, galeria: File[] = []): Observable<Publicacion> {
    return this.request(this.http.put<Publicacion>(`${this.baseUrl}/publicaciones/${id}`, this.multipart(payload, portada, galeria)));
  }
  private multipart(payload: PublicacionPayload, portada?: File, galeria: File[] = []): FormData {
    const form = new FormData();
    form.append('data', new Blob([JSON.stringify(payload)], { type: 'application/json' }));
    if (portada) form.append('portada', portada, portada.name);
    galeria.forEach(file => form.append('galeria', file, file.name));
    return form;
  }
  cambiarEstadoPublicacion(id: string, estado: 'DRAFT' | 'PUBLISHED'): Observable<Publicacion> {
    const action = estado === 'PUBLISHED' ? 'publicar' : 'despublicar';
    return this.request(this.http.post<Publicacion>(`${this.baseUrl}/publicaciones/${id}/${action}`, {}));
  }
  eliminarPublicacion(id: string): Observable<void> { return this.request(this.http.delete<void>(`${this.baseUrl}/publicaciones/${id}`)); }

  listarConvocatorias(): Observable<Convocatoria[]> { return this.request(this.http.get<Convocatoria[]>(`${this.baseUrl}/convocatorias`)); }
  obtenerConvocatoria(id: string): Observable<Convocatoria> { return this.request(this.http.get<Convocatoria>(`${this.baseUrl}/convocatorias/${id}`)); }
  crearConvocatoria(payload: ConvocatoriaPayload): Observable<Convocatoria> { return this.request(this.http.post<Convocatoria>(`${this.baseUrl}/convocatorias`, payload)); }
  actualizarConvocatoria(id: string, payload: ConvocatoriaPayload): Observable<Convocatoria> { return this.request(this.http.put<Convocatoria>(`${this.baseUrl}/convocatorias/${id}`, payload)); }
  cambiarEstadoConvocatoria(id: string, estado: 'DRAFT' | 'PUBLISHED' | 'CLOSED'): Observable<Convocatoria> {
    const action = estado === 'PUBLISHED' ? 'publicar' : estado === 'CLOSED' ? 'cerrar' : 'despublicar';
    return this.request(this.http.post<Convocatoria>(`${this.baseUrl}/convocatorias/${id}/${action}`, {}));
  }

  listarPostulaciones(convocatoriaId: string, estado?: PostulacionEstado): Observable<Postulacion[]> {
    let params = new HttpParams().set('convocatoriaId', convocatoriaId);
    if (estado) params = params.set('estado', estado);
    return this.request(this.http.get<Postulacion[]>(`${this.baseUrl}/postulaciones`, { params }));
  }
  obtenerPostulacion(id: string): Observable<Postulacion> { return this.request(this.http.get<Postulacion>(`${this.baseUrl}/postulaciones/${id}`)); }
  cambiarEstadoPostulacion(id: string, estado: PostulacionEstado): Observable<Postulacion> { return this.request(this.http.patch<Postulacion>(`${this.baseUrl}/postulaciones/${id}/estado`, { estado })); }
  descargarCv(id: string): Observable<Blob> { return this.request(this.http.get(`${this.baseUrl}/postulaciones/${id}/cv`, { responseType: 'blob' })); }

  listarContactos(): Observable<Contacto[]> { return this.request(this.http.get<Contacto[]>(`${this.baseUrl}/contactos`)); }
  marcarContacto(id: string, estado: 'READ' | 'UNREAD'): Observable<Contacto> { return this.request(this.http.patch<Contacto>(`${this.baseUrl}/contactos/${id}`, { estado })); }
  listarDestinatarios(): Observable<Destinatario[]> { return this.request(this.http.get<Destinatario[]>(`${this.baseUrl}/destinatarios`)); }
  crearDestinatario(payload: DestinatarioPayload): Observable<Destinatario> { return this.request(this.http.post<Destinatario>(`${this.baseUrl}/destinatarios`, payload)); }
  actualizarDestinatario(id: string, payload: DestinatarioPayload): Observable<Destinatario> { return this.request(this.http.put<Destinatario>(`${this.baseUrl}/destinatarios/${id}`, payload)); }
  eliminarDestinatario(id: string): Observable<void> { return this.request(this.http.delete<void>(`${this.baseUrl}/destinatarios/${id}`)); }
}
