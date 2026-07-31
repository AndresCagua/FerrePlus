import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';
import { environment } from '../../environments/environment';
import { AuthResponse, Usuario } from './models';
import { RUTAS_POR_PERMISO } from './rutas-por-permiso';

export const SESSION_KEYS = {
  token: 'ferreplus_token',
  email: 'ferreplus_email',
  nombre: 'ferreplus_nombre',
  rol: 'ferreplus_rol',
  usuarioId: 'ferreplus_usuarioId',
  permisos: 'ferreplus_permisos'
} as const;

export interface CurrentUser {
  email: string;
  nombre: string;
  rol: string;
  usuarioId: number;
  permisos: string[];
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = `${environment.apiUrl}/auth`;
  private usuariosApiUrl = `${environment.apiUrl}/usuarios`;
  private currentUserSubject = new BehaviorSubject<CurrentUser | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    this.loadStoredUser();
  }

  private loadStoredUser(): void {
    const token = sessionStorage.getItem(SESSION_KEYS.token);
    const email = sessionStorage.getItem(SESSION_KEYS.email);
    if (token && email) {
      this.currentUserSubject.next({
        email,
        nombre: sessionStorage.getItem(SESSION_KEYS.nombre) || '',
        rol: sessionStorage.getItem(SESSION_KEYS.rol) || '',
        usuarioId: Number(sessionStorage.getItem(SESSION_KEYS.usuarioId)) || 0,
        permisos: this.readPermisos()
      });
    }
  }

  private readPermisos(): string[] {
    const raw = sessionStorage.getItem(SESSION_KEYS.permisos);
    if (!raw) {
      return [];
    }
    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  private writePermisos(permisos: string[]): void {
    sessionStorage.setItem(SESSION_KEYS.permisos, JSON.stringify(permisos ?? []));
  }

  private buildCurrentUser(
    email: string,
    nombre: string,
    rol: string,
    usuarioId: number,
    permisos: string[]
  ): CurrentUser {
    return { email, nombre, rol, usuarioId, permisos };
  }

  login(email: string, password: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.apiUrl}/login`, { email, password }).pipe(
      tap(response => {
        const permisos = response.permisos ?? [];
        sessionStorage.setItem(SESSION_KEYS.token, response.token);
        sessionStorage.setItem(SESSION_KEYS.email, response.email);
        sessionStorage.setItem(SESSION_KEYS.nombre, response.nombre);
        sessionStorage.setItem(SESSION_KEYS.rol, response.rol);
        sessionStorage.setItem(SESSION_KEYS.usuarioId, String(response.usuarioId));
        this.writePermisos(permisos);
        this.currentUserSubject.next(
          this.buildCurrentUser(response.email, response.nombre, response.rol, response.usuarioId, permisos)
        );
      })
    );
  }

  register(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/register`, data);
  }

  /**
   * Refresca los permisos efectivos desde `GET /api/usuarios/me` (Decisión 6).
   * Actualiza sessionStorage y el CurrentUser. Se invoca en cada navegación
   * desde el AuthGuard: los cambios de rol/overrides aplican sin re-login.
   */
  refreshPermisos(): Observable<Usuario> {
    return this.http.get<Usuario>(`${this.usuariosApiUrl}/me`).pipe(
      tap(usuario => {
        const permisos = usuario.permisos ?? [];
        sessionStorage.setItem(SESSION_KEYS.email, usuario.email);
        sessionStorage.setItem(SESSION_KEYS.nombre, usuario.nombre);
        sessionStorage.setItem(SESSION_KEYS.rol, usuario.rolNombre);
        sessionStorage.setItem(SESSION_KEYS.usuarioId, String(usuario.id));
        this.writePermisos(permisos);
        this.currentUserSubject.next(
          this.buildCurrentUser(usuario.email, usuario.nombre, usuario.rolNombre, usuario.id, permisos)
        );
      })
    );
  }

  logout(): void {
    Object.values(SESSION_KEYS).forEach(key => sessionStorage.removeItem(key));
    this.currentUserSubject.next(null);
  }

  getToken(): string | null {
    return sessionStorage.getItem(SESSION_KEYS.token);
  }

  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  getCurrentUser(): CurrentUser | null {
    return this.currentUserSubject.value;
  }

  hasPermission(codigo: string): boolean {
    return this.readPermisos().includes(codigo);
  }

  hasAnyPermission(codigos: string[]): boolean {
    if (!codigos || codigos.length === 0) {
      return true;
    }
    const permisos = new Set(this.readPermisos());
    return codigos.some(codigo => permisos.has(codigo));
  }

  /**
   * Ruta home del usuario: la PRIMERA ruta top-level (en orden de
   * `RUTAS_POR_PERMISO`, DASHBOARD primero) para la que tiene permiso.
   * Retorna `null` cuando el usuario no tiene NINGUNA página accesible
   * (sin permisos asignados) — el login/guard deben manejar ese caso.
   */
  getHomeRoute(): string | null {
    const ruta = RUTAS_POR_PERMISO.find(item =>
      !item.permissions ||
      item.permissions.length === 0 ||
      this.hasAnyPermission(item.permissions)
    );
    return ruta ? ruta.route : null;
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
