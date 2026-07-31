import { TestBed } from '@angular/core/testing';
import { Router, ActivatedRouteSnapshot, RouterStateSnapshot } from '@angular/router';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { of, throwError } from 'rxjs';
import { AuthGuard } from './auth.guard';
import { AuthService } from './auth.service';
import { Usuario } from './models';

describe('AuthGuard', () => {
  let guard: AuthGuard;
  let authServiceMock: {
    isLoggedIn: ReturnType<typeof vi.fn>;
    refreshPermisos: ReturnType<typeof vi.fn>;
    hasAnyPermission: ReturnType<typeof vi.fn>;
    hasAnyRole: ReturnType<typeof vi.fn>;
    getHomeRoute: ReturnType<typeof vi.fn>;
    logout: ReturnType<typeof vi.fn>;
  };
  let routerMock: {
    navigate: ReturnType<typeof vi.fn>;
    navigateByUrl: ReturnType<typeof vi.fn>;
  };

  const usuarioMock: Usuario = {
    id: 3,
    nombre: 'Juan',
    email: 'juan@ferreplus.com',
    telefono: '',
    activo: true,
    rolId: 2,
    rolNombre: 'VENDEDOR',
    permisos: ['DASHBOARD_VER', 'GASTOS_VER']
  };

  function routeWith(data: Record<string, unknown> = {}): ActivatedRouteSnapshot {
    return { data } as unknown as ActivatedRouteSnapshot;
  }

  function stateWith(url: string): RouterStateSnapshot {
    return { url } as unknown as RouterStateSnapshot;
  }

  beforeEach(() => {
    authServiceMock = {
      isLoggedIn: vi.fn(),
      refreshPermisos: vi.fn(),
      hasAnyPermission: vi.fn(),
      hasAnyRole: vi.fn(),
      getHomeRoute: vi.fn(),
      logout: vi.fn()
    };
    routerMock = { navigate: vi.fn(), navigateByUrl: vi.fn() };

    TestBed.configureTestingModule({
      providers: [
        AuthGuard,
        { provide: AuthService, useValue: authServiceMock },
        { provide: Router, useValue: routerMock }
      ]
    });
    guard = TestBed.inject(AuthGuard);
  });

  it('sin token redirige a /auth con returnUrl y bloquea', () => {
    authServiceMock.isLoggedIn.mockReturnValue(false);

    guard.canActivate(routeWith(), stateWith('/usuarios')).subscribe(allowed => {
      expect(allowed).toBe(false);
    });

    expect(routerMock.navigate).toHaveBeenCalledWith(['/auth'], {
      queryParams: { returnUrl: '/usuarios' }
    });
    expect(authServiceMock.refreshPermisos).not.toHaveBeenCalled();
  });

  it('con token y sin data.permissions refresca permisos y permite', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(of(usuarioMock));

    guard.canActivate(routeWith(), stateWith('/dashboard')).subscribe(allowed => {
      expect(allowed).toBe(true);
    });

    expect(authServiceMock.refreshPermisos).toHaveBeenCalled();
    expect(authServiceMock.hasAnyPermission).not.toHaveBeenCalled();
    expect(routerMock.navigate).not.toHaveBeenCalled();
    expect(routerMock.navigateByUrl).not.toHaveBeenCalled();
  });

  it('permite cuando el usuario cumple data.permissions', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(of(usuarioMock));
    authServiceMock.hasAnyPermission.mockReturnValue(true);

    guard
      .canActivate(routeWith({ permissions: ['ROLES_VER', 'USUARIOS_VER'] }), stateWith('/roles'))
      .subscribe(allowed => {
        expect(allowed).toBe(true);
      });

    expect(authServiceMock.hasAnyPermission).toHaveBeenCalledWith(['ROLES_VER', 'USUARIOS_VER']);
    expect(routerMock.navigate).not.toHaveBeenCalled();
    expect(routerMock.navigateByUrl).not.toHaveBeenCalled();
  });

  it('bloquea y redirige a la PRIMERA ruta permitida cuando NO cumple data.permissions', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(of(usuarioMock));
    authServiceMock.hasAnyPermission.mockReturnValue(false);
    authServiceMock.getHomeRoute.mockReturnValue('/productos');

    guard
      .canActivate(routeWith({ permissions: ['ROLES_VER'] }), stateWith('/roles'))
      .subscribe(allowed => {
        expect(allowed).toBe(false);
      });

    expect(routerMock.navigateByUrl).toHaveBeenCalledWith('/productos');
    expect(routerMock.navigate).not.toHaveBeenCalled();
    expect(authServiceMock.logout).not.toHaveBeenCalled();
  });

  it('evita el bucle de redirección cuando la ruta prohibida ya es el home', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(of(usuarioMock));
    authServiceMock.hasAnyPermission.mockReturnValue(false);
    authServiceMock.getHomeRoute.mockReturnValue('/productos');

    guard
      .canActivate(routeWith({ permissions: ['PRODUCTOS_VER'] }), stateWith('/productos'))
      .subscribe(allowed => {
        expect(allowed).toBe(false);
      });

    expect(routerMock.navigateByUrl).not.toHaveBeenCalled();
  });

  it('usuario sin NINGUNA ruta accesible → logout y redirect a /auth', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(of(usuarioMock));
    authServiceMock.hasAnyPermission.mockReturnValue(false);
    authServiceMock.getHomeRoute.mockReturnValue(null);

    guard
      .canActivate(routeWith({ permissions: ['ROLES_VER'] }), stateWith('/roles'))
      .subscribe(allowed => {
        expect(allowed).toBe(false);
      });

    expect(authServiceMock.logout).toHaveBeenCalled();
    expect(routerMock.navigate).toHaveBeenCalledWith(['/auth']);
  });

  it('mantiene la compatibilidad con data.roles (roles cumplidos → permite)', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(of(usuarioMock));
    authServiceMock.hasAnyRole.mockReturnValue(true);

    guard
      .canActivate(routeWith({ roles: ['ADMIN', 'GERENTE'] }), stateWith('/reportes'))
      .subscribe(allowed => {
        expect(allowed).toBe(true);
      });

    expect(authServiceMock.hasAnyRole).toHaveBeenCalledWith(['ADMIN', 'GERENTE']);
  });

  it('bloquea con data.roles no cumplidos → redirige a la primera ruta permitida', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(of(usuarioMock));
    authServiceMock.hasAnyRole.mockReturnValue(false);
    authServiceMock.getHomeRoute.mockReturnValue('/gastos');

    guard
      .canActivate(routeWith({ roles: ['ADMIN'] }), stateWith('/reportes'))
      .subscribe(allowed => {
        expect(allowed).toBe(false);
      });

    expect(routerMock.navigateByUrl).toHaveBeenCalledWith('/gastos');
  });

  it('si el refresh falla redirige a /auth con returnUrl y bloquea', () => {
    authServiceMock.isLoggedIn.mockReturnValue(true);
    authServiceMock.refreshPermisos.mockReturnValue(throwError(() => new Error('401')));

    guard.canActivate(routeWith(), stateWith('/roles')).subscribe(allowed => {
      expect(allowed).toBe(false);
    });

    expect(routerMock.navigate).toHaveBeenCalledWith(['/auth'], {
      queryParams: { returnUrl: '/roles' }
    });
  });
});
