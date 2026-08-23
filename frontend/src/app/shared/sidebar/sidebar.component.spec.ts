import { BehaviorSubject } from 'rxjs';
import { TestBed } from '@angular/core/testing';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { ComponentFixture } from '@angular/core/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { SharedModule } from '../shared.module';
import { AuthService, CurrentUser } from '../../core/auth.service';
import { RutaPorPermiso } from '../../core/rutas-por-permiso';
import { SidebarComponent } from './sidebar.component';

describe('SidebarComponent', () => {
  afterEach(() => localStorage.clear());

  it('mantiene el menu estable y lo recalcula cuando cambian los permisos', () => {
    const currentUser$ = new BehaviorSubject<CurrentUser | null>(null);
    const permisos = new Set<string>();
    const authService = {
      currentUser$,
      hasAnyPermission: (required: string[]) => required.some(permission => permisos.has(permission))
    } as unknown as AuthService;
    const sidebar = TestBed.runInInjectionContext(() => new SidebarComponent(authService));

    const initialMenu = sidebar.visibleMenuItems;
    expect(sidebar.visibleMenuItems).toBe(initialMenu);

    permisos.add('CONTABILIDAD_CONTACTOS_VER');
    currentUser$.next({
      email: 'usuario@ferreplus.com',
      nombre: 'Usuario',
      rol: 'USUARIO',
      usuarioId: 1,
      permisos: ['CONTABILIDAD_CONTACTOS_VER']
    });

    const talento = sidebar.visibleMenuItems.find(item => item.route === '/talento');
    const contabilidad = sidebar.visibleMenuItems.find(item => item.label === 'Contabilidad');
    expect(talento).toBeUndefined();
    expect(contabilidad?.children?.map(child => child.route)).toEqual(['/talento/contactos']);
    expect(sidebar.visibleMenuItems).not.toBe(initialMenu);
  });

  it('usa la ruta como identidad estable para items padre e hijo', () => {
    const item: RutaPorPermiso = {
      label: 'Productos',
      icon: 'inventory_2',
      route: '/productos'
    };
    const sidebar = TestBed.runInInjectionContext(() => new SidebarComponent({
      currentUser$: new BehaviorSubject<CurrentUser | null>(null),
      hasAnyPermission: () => false
    } as unknown as AuthService));

    expect(sidebar.trackByRoute(0, item)).toBe('/productos');
  });

  it('alterna un modulo sin navegar y persiste solo su estado booleano', () => {
    const sidebar = TestBed.runInInjectionContext(() => new SidebarComponent({
      currentUser$: new BehaviorSubject<CurrentUser | null>(null),
      hasAnyPermission: () => false
    } as unknown as AuthService));
    const module: RutaPorPermiso = {
      label: 'Bodega', icon: 'warehouse', route: '/bodega', module: true, children: []
    };

    sidebar.toggleModule(module);

    expect(sidebar.isExpanded(module)).toBe(true);
    expect(JSON.parse(localStorage.getItem('ferreplus_menu_v1') || '{}')).toEqual({ '/bodega': true });
  });

  it('Space alterna y evita el desplazamiento de la pagina', () => {
    const sidebar = TestBed.runInInjectionContext(() => new SidebarComponent({
      currentUser$: new BehaviorSubject<CurrentUser | null>(null),
      hasAnyPermission: () => false
    } as unknown as AuthService));
    const module: RutaPorPermiso = {
      label: 'Bodega', icon: 'warehouse', route: '/bodega', module: true, children: []
    };
    const event = { key: ' ', preventDefault: () => undefined } as unknown as KeyboardEvent;

    sidebar.onModuleKeydown(event, module);

    expect(sidebar.isExpanded(module)).toBe(true);
  });

  it('Enter alterna el modulo y evita la navegacion implicita', () => {
    const sidebar = TestBed.runInInjectionContext(() => new SidebarComponent({
      currentUser$: new BehaviorSubject<CurrentUser | null>(null),
      hasAnyPermission: () => false
    } as unknown as AuthService));
    const module: RutaPorPermiso = {
      label: 'Bodega', icon: 'warehouse', route: '/bodega', module: true, children: []
    };
    const preventDefault = vi.fn();
    const event = { key: 'Enter', preventDefault } as unknown as KeyboardEvent;

    sidebar.onModuleKeydown(event, module);

    expect(sidebar.isExpanded(module)).toBe(true);
    expect(preventDefault).toHaveBeenCalledOnce();
  });

  it('renderiza controles ARIA reales y no deja hijos colapsados en el DOM', () => {
    const currentUser$ = new BehaviorSubject<CurrentUser | null>({
      email: 'editor@ferreplus.com', nombre: 'Editor', rol: 'EDITOR', usuarioId: 1,
      permisos: ['DASHBOARD_VER', 'PRODUCTOS_VER']
    });
    TestBed.configureTestingModule({
      imports: [SharedModule, RouterTestingModule],
      providers: [{
        provide: AuthService,
        useValue: {
          currentUser$,
          hasAnyPermission: (permissions: string[]) => permissions.some(permission =>
            currentUser$.value?.permisos.includes(permission)
          ),
          getCurrentUser: () => currentUser$.value,
        }
      }]
    });
    const fixture: ComponentFixture<SidebarComponent> = TestBed.createComponent(SidebarComponent);
    fixture.detectChanges();

    const button = fixture.nativeElement.querySelector('button[aria-controls="menu-group-bodega"]') as HTMLButtonElement;
    expect(button).toBeTruthy();
    expect(button.getAttribute('aria-label')).toContain('Bodega');
    expect(button.getAttribute('aria-expanded')).toBe('false');
    expect(fixture.nativeElement.querySelector('#menu-group-bodega')).toBeNull();

    button.focus();
    button.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
    fixture.detectChanges();

    expect(button.getAttribute('aria-expanded')).toBe('true');
    expect(fixture.nativeElement.querySelector('#menu-group-bodega a')).toBeTruthy();
    expect(document.activeElement).toBe(button);
  });
});
