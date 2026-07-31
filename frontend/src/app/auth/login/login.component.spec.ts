import { TestBed } from '@angular/core/testing';
import { ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { of, throwError } from 'rxjs';
import { LoginComponent } from './login.component';
import { AuthService } from '../../core/auth.service';
import { AuthResponse } from '../../core/models';

describe('LoginComponent (navegación post-login)', () => {
  let component: LoginComponent;
  let authMock: {
    isLoggedIn: ReturnType<typeof vi.fn>;
    login: ReturnType<typeof vi.fn>;
    getHomeRoute: ReturnType<typeof vi.fn>;
    hasAnyPermission: ReturnType<typeof vi.fn>;
  };
  let routerMock: {
    navigateByUrl: ReturnType<typeof vi.fn>;
    navigate: ReturnType<typeof vi.fn>;
  };
  let routeMock: {
    snapshot: { queryParamMap: { get: ReturnType<typeof vi.fn> } };
  };

  const loginResponse: AuthResponse = {
    token: 'abc',
    email: 'prueba@ferreplus.com',
    nombre: 'Prueba',
    rol: 'PRUEBA',
    usuarioId: 7,
    permisos: ['PRODUCTOS_VER', 'GASTOS_VER']
  };

  beforeEach(() => {
    authMock = {
      isLoggedIn: vi.fn(),
      login: vi.fn(),
      getHomeRoute: vi.fn(),
      hasAnyPermission: vi.fn()
    };
    routerMock = { navigateByUrl: vi.fn(), navigate: vi.fn() };
    routeMock = {
      snapshot: {
        queryParamMap: { get: vi.fn(() => null) }
      }
    };

    TestBed.configureTestingModule({
      imports: [
        NoopAnimationsModule,
        ReactiveFormsModule,
        MatCardModule,
        MatFormFieldModule,
        MatInputModule,
        MatButtonModule,
        MatIconModule,
        MatProgressSpinnerModule
      ],
      declarations: [LoginComponent],
      providers: [
        { provide: AuthService, useValue: authMock },
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: routeMock }
      ]
    });
    component = TestBed.createComponent(LoginComponent).componentInstance;
    component.loginForm.setValue({ email: 'prueba@ferreplus.com', password: '1234' });
  });

  it('ngOnInit con sesión activa navega a getHomeRoute()', () => {
    authMock.isLoggedIn.mockReturnValue(true);
    authMock.getHomeRoute.mockReturnValue('/productos');

    component.ngOnInit();

    expect(routerMock.navigateByUrl).toHaveBeenCalledWith('/productos');
  });

  it('ngOnInit con sesión activa SIN permisos muestra mensaje y no navega', () => {
    authMock.isLoggedIn.mockReturnValue(true);
    authMock.getHomeRoute.mockReturnValue(null);

    component.ngOnInit();

    expect(routerMock.navigateByUrl).not.toHaveBeenCalled();
    expect(component.errorMessage).toContain('no tiene permisos');
  });

  it('onSubmit con login OK navega a getHomeRoute()', () => {
    authMock.isLoggedIn.mockReturnValue(false);
    authMock.getHomeRoute.mockReturnValue('/productos');
    authMock.login.mockReturnValue(of(loginResponse));
    routerMock.navigateByUrl.mockResolvedValue(true);

    component.onSubmit();

    expect(authMock.login).toHaveBeenCalledWith('prueba@ferreplus.com', '1234');
    expect(routerMock.navigateByUrl).toHaveBeenCalledWith('/productos');
    expect(component.errorMessage).toBe('');
  });

  it('onSubmit respeta returnUrl cuando el usuario tiene permiso para esa ruta', () => {
    authMock.isLoggedIn.mockReturnValue(false);
    authMock.getHomeRoute.mockReturnValue('/productos');
    authMock.hasAnyPermission.mockReturnValue(true);
    routeMock.snapshot.queryParamMap.get.mockReturnValue('/roles');
    authMock.login.mockReturnValue(of(loginResponse));
    routerMock.navigateByUrl.mockResolvedValue(true);

    component.onSubmit();

    expect(authMock.hasAnyPermission).toHaveBeenCalled();
    expect(routerMock.navigateByUrl).toHaveBeenCalledWith('/roles');
  });

  it('onSubmit NO respeta returnUrl sin permiso → cae a getHomeRoute()', () => {
    authMock.isLoggedIn.mockReturnValue(false);
    authMock.getHomeRoute.mockReturnValue('/productos');
    authMock.hasAnyPermission.mockReturnValue(false);
    routeMock.snapshot.queryParamMap.get.mockReturnValue('/roles');
    authMock.login.mockReturnValue(of(loginResponse));
    routerMock.navigateByUrl.mockResolvedValue(true);

    component.onSubmit();

    expect(routerMock.navigateByUrl).toHaveBeenCalledWith('/productos');
  });

  it('onSubmit con login OK SIN permisos muestra error claro y NO navega', () => {
    authMock.isLoggedIn.mockReturnValue(false);
    authMock.getHomeRoute.mockReturnValue(null);
    authMock.login.mockReturnValue(of(loginResponse));

    component.onSubmit();

    expect(routerMock.navigateByUrl).not.toHaveBeenCalled();
    expect(component.errorMessage).toContain('no tiene permisos');
    expect(component.loading).toBe(false);
  });

  it('onSubmit con error 401 muestra credenciales incorrectas', () => {
    authMock.isLoggedIn.mockReturnValue(false);
    authMock.login.mockReturnValue(throwError(() => ({ status: 401 })));

    component.onSubmit();

    expect(component.loading).toBe(false);
    expect(component.errorMessage).toContain('Credenciales');
  });
});
