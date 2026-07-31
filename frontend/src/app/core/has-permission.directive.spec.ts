import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { HasPermissionDirective } from './has-permission.directive';
import { AuthService } from './auth.service';

@Component({
  template: `
    <button id="single" *appHasPermission="'PRODUCTOS_CREAR'">Nuevo producto</button>
    <button id="any" *appHasPermission="['PRODUCTOS_VER', 'CATEGORIAS_VER']">Ver catálogo</button>
    <button id="always">Siempre visible</button>
  `,
  standalone: false
})
class HostComponent {}

describe('HasPermissionDirective', () => {
  let fixture: ComponentFixture<HostComponent>;
  let authMock: {
    hasPermission: ReturnType<typeof vi.fn>;
    hasAnyPermission: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    authMock = {
      hasPermission: vi.fn(),
      hasAnyPermission: vi.fn()
    };
    TestBed.configureTestingModule({
      declarations: [HostComponent, HasPermissionDirective],
      providers: [{ provide: AuthService, useValue: authMock }]
    });
    fixture = TestBed.createComponent(HostComponent);
  });

  it('muestra el elemento cuando el usuario tiene el permiso', () => {
    authMock.hasPermission.mockReturnValue(true);
    authMock.hasAnyPermission.mockReturnValue(true);

    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('#single')).toBeTruthy();
    expect(fixture.nativeElement.querySelector('#any')).toBeTruthy();
    expect(fixture.nativeElement.querySelector('#always')).toBeTruthy();
  });

  it('oculta el elemento cuando el usuario NO tiene el permiso', () => {
    authMock.hasPermission.mockReturnValue(false);
    authMock.hasAnyPermission.mockReturnValue(false);

    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('#single')).toBeNull();
    expect(fixture.nativeElement.querySelector('#any')).toBeNull();
    // Los elementos sin la directiva no se ven afectados
    expect(fixture.nativeElement.querySelector('#always')).toBeTruthy();
  });

  it('con un array usa hasAnyPermission', () => {
    authMock.hasPermission.mockReturnValue(false);
    authMock.hasAnyPermission.mockReturnValue(true);

    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('#any')).toBeTruthy();
    expect(authMock.hasAnyPermission).toHaveBeenCalledWith(['PRODUCTOS_VER', 'CATEGORIAS_VER']);
  });
});
