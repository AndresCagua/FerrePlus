import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';
import { environment } from '../../environments/environment';
import { AuthResponse } from './models';

export interface CurrentUser {
  email: string;
  nombre: string;
  rol: string;
  usuarioId: number;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = `${environment.apiUrl}/auth`;
  private currentUserSubject = new BehaviorSubject<CurrentUser | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    this.loadStoredUser();
  }

  private loadStoredUser(): void {
    const token = sessionStorage.getItem('ferreplus_token');
    const email = sessionStorage.getItem('ferreplus_email');
    const nombre = sessionStorage.getItem('ferreplus_nombre');
    const rol = sessionStorage.getItem('ferreplus_rol');
    const usuarioId = sessionStorage.getItem('ferreplus_usuarioId');
    if (token && email) {
      this.currentUserSubject.next({
        email,
        nombre: nombre || '',
        rol: rol || '',
        usuarioId: usuarioId ? Number(usuarioId) : 0
      });
    }
  }

  login(email: string, password: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/login`, { email, password }).pipe(
      tap(response => {
        sessionStorage.setItem('ferreplus_token', response.token);
        sessionStorage.setItem('ferreplus_email', response.email);
        sessionStorage.setItem('ferreplus_nombre', response.nombre);
        sessionStorage.setItem('ferreplus_rol', response.rol);
        sessionStorage.setItem('ferreplus_usuarioId', String(response.usuarioId));
        this.currentUserSubject.next({
          email: response.email,
          nombre: response.nombre,
          rol: response.rol,
          usuarioId: response.usuarioId
        });
      })
    );
  }

  register(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/register`, data);
  }

  logout(): void {
    sessionStorage.removeItem('ferreplus_token');
    sessionStorage.removeItem('ferreplus_email');
    sessionStorage.removeItem('ferreplus_nombre');
    sessionStorage.removeItem('ferreplus_rol');
    sessionStorage.removeItem('ferreplus_usuarioId');
    this.currentUserSubject.next(null);
  }

  getToken(): string | null {
    return sessionStorage.getItem('ferreplus_token');
  }

  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  getCurrentUser(): CurrentUser | null {
    return this.currentUserSubject.value;
  }

  hasRole(role: string): boolean {
    const user = this.getCurrentUser();
    return user?.rol === role;
  }

  hasAnyRole(roles: string[]): boolean {
    const user = this.getCurrentUser();
    return !!user && roles.includes(user.rol);
  }
}
