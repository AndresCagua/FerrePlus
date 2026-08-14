import { TestBed } from '@angular/core/testing';
import {
  HttpClientTestingModule,
  HttpTestingController
} from '@angular/common/http/testing';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { AuthService, SESSION_KEYS } from './auth.service';
import { environment } from '../../environments/environment';
import { AuthResponse, Usuario } from './models';

describe('AuthService (permisos)', () => {
  let service: AuthService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    sessionStorage.clear();
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [AuthService]
    });
    service = TestBed.inject(AuthService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
    sessionStorage.clear();
  });

  it('login almacena permisos en sessionStorage y actualiza el CurrentUser', () => {
    const response: AuthResponse = {
      token: 'abc123',
      email: 'vendedor@ferreplus.com',
      nombre: 'Vendedor',
      rol: 'VENDEDOR',
      usuarioId: 2,
      permisos: ['DASHBOARD_VER', 'VENTAS_VER', 'GASTOS_VER']
    };

    let completed = false;
    service.login('vendedor@ferreplus.com', 'clave123').subscribe(() => {
      completed = true;
    });
    httpMock.expectOne(`${environment.apiUrl}/auth/login`).flush(response);

    expect(completed).toBe(true);
    expect(JSON.parse(sessionStorage.getItem(SESSION_KEYS.permisos) || '[]')).toEqual([
      'DASHBOARD_VER',
      'VENTAS_VER',
      'GASTOS_VER'
    ]);
    expect(service.getCurrentUser()?.permisos).toEqual([
      'DASHBOARD_VER',
      'VENTAS_VER',
      'GASTOS_VER'
    ]);
    expect(service.hasPermission('VENTAS_VER')).toBe(true);
    expect(service.hasPermission('REPORTES_VER')).toBe(false);
  });

  it('login tolera una respuesta sin permisos (compatibilidad hacia atrás)', () => {
    const response = {
      token: 'abc123',
      email: 'admin@ferreplus.com',
      nombre: 'Admin',
      rol: 'ADMIN',
      usuarioId: 1
    } as AuthResponse;

    service.login('admin@ferreplus.com', 'clave').subscribe();
    httpMock.expectOne(`${environment.apiUrl}/auth/login`).flush(response);

    expect(JSON.parse(sessionStorage.getItem(SESSION_KEYS.permisos) || '[]')).toEqual([]);
    expect(service.hasPermission('CUALQUIERA')).toBe(false);
  });

  it('refreshPermisos actualiza sessionStorage, CurrentUser y los permisos desde /me', () => {
    sessionStorage.setItem(SESSION_KEYS.token, 'token-viejo');
    const me: Usuario = {
      id: 3,
      nombre: 'Juan',
      email: 'juan@ferreplus.com',
      telefono: '',
      activo: true,
      rolId: 2,
      rolNombre: 'VENDEDOR',
      permisos: ['DASHBOARD_VER', 'GASTOS_VER'],
      overrides: [{ permisoCodigo: 'GASTOS_VER', concedido: true }]
    };

    let refreshed: Usuario | undefined;
    service.refreshPermisos().subscribe(u => {
      refreshed = u;
    });
    httpMock.expectOne(`${environment.apiUrl}/usuarios/me`).flush(me);

    expect(refreshed?.rolNombre).toBe('VENDEDOR');
    expect(sessionStorage.getItem(SESSION_KEYS.rol)).toBe('VENDEDOR');
    expect(sessionStorage.getItem(SESSION_KEYS.usuarioId)).toBe('3');
    expect(JSON.parse(sessionStorage.getItem(SESSION_KEYS.permisos) || '[]')).toEqual([
      'DASHBOARD_VER',
      'GASTOS_VER'
    ]);
    expect(service.hasAnyPermission(['GASTOS_VER', 'REPORTES_VER'])).toBe(true);
    expect(service.hasAnyPermission(['REPORTES_VER', 'PRODUCTOS_VER'])).toBe(false);
  });

  it('hasAnyPermission sin códigos (rutas abiertas) permite el acceso', () => {
    expect(service.hasAnyPermission([])).toBe(true);
    expect(service.hasAnyPermission(undefined as unknown as string[])).toBe(true);
  });

  it('logout limpia sessionStorage y el CurrentUser', () => {
    const response: AuthResponse = {
      token: 'abc',
      email: 'u@ferreplus.com',
      nombre: 'U',
      rol: 'ADMIN',
      usuarioId: 1,
      permisos: ['DASHBOARD_VER']
    };
    service.login('u@ferreplus.com', 'clave').subscribe();
    httpMock.expectOne(`${environment.apiUrl}/auth/login`).flush(response);

    expect(service.isLoggedIn()).toBe(true);

    service.logout();

    expect(sessionStorage.getItem(SESSION_KEYS.token)).toBeNull();
    expect(sessionStorage.getItem(SESSION_KEYS.permisos)).toBeNull();
    expect(service.getCurrentUser()).toBeNull();
    expect(service.isLoggedIn()).toBe(false);
  });

  it('hasRole/hasAnyRole usan el rol del CurrentUser', () => {
    const response: AuthResponse = {
      token: 'abc',
      email: 'j@ferreplus.com',
      nombre: 'Juan',
      rol: 'GERENTE',
      usuarioId: 4,
      permisos: ['DASHBOARD_VER']
    };
    service.login('j@ferreplus.com', 'clave').subscribe();
    httpMock.expectOne(`${environment.apiUrl}/auth/login`).flush(response);

    expect(service.hasRole('GERENTE')).toBe(true);
    expect(service.hasRole('VENDEDOR')).toBe(false);
    expect(service.hasAnyRole(['ADMIN', 'GERENTE'])).toBe(true);
    expect(service.hasAnyRole(['VENDEDOR'])).toBe(false);
  });
});

describe('AuthService.getHomeRoute (navegación post-login)', () => {
  let service: AuthService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    sessionStorage.clear();
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [AuthService]
    });
    service = TestBed.inject(AuthService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
    sessionStorage.clear();
  });

  it('usuario con DASHBOARD_VER → home /dashboard', () => {
    sessionStorage.setItem(
      SESSION_KEYS.permisos,
      JSON.stringify(['DASHBOARD_VER', 'GASTOS_VER'])
    );
    expect(service.getHomeRoute()).toBe('/dashboard');
  });

  it('usuario SIN DASHBOARD_VER pero con PRODUCTOS_VER → home /productos', () => {
    sessionStorage.setItem(
      SESSION_KEYS.permisos,
      JSON.stringify(['PRODUCTOS_VER', 'CLIENTES_CREAR', 'GASTOS_VER'])
    );
    expect(service.getHomeRoute()).toBe('/productos');
  });

  it('usuario sin DASHBOARD_VER con permisos posteriores en el menú → primera ruta permitida en orden', () => {
    sessionStorage.setItem(
      SESSION_KEYS.permisos,
      JSON.stringify(['GASTOS_VER', 'REPORTES_VER'])
    );
    // Orden del menú: ... movimientos, gastos, usuarios, roles, reportes
    expect(service.getHomeRoute()).toBe('/gastos');
  });

  it('usuario SIN ningún permiso de módulo → no tiene una ruta de página accesible', () => {
    sessionStorage.setItem(SESSION_KEYS.permisos, JSON.stringify([]));
    expect(service.getHomeRoute()).toBeNull();
  });

  it('sin permisos almacenados en sessionStorage → no tiene una ruta de página accesible', () => {
    sessionStorage.removeItem(SESSION_KEYS.permisos);
    expect(service.getHomeRoute()).toBeNull();
  });
});
