import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';
import { AuthService } from './auth.service';

/**
 * Directiva estructural de permisos (R7): oculta del DOM el elemento si el
 * usuario no tiene el/los permiso(s).
 *
 * Uso:
 *   *appHasPermission="'PRODUCTOS_CREAR'"
 *   *appHasPermission="['PRODUCTOS_CREAR', 'PRODUCTOS_EDITAR']"   (any)
 */
@Directive({
  selector: '[appHasPermission]',
  standalone: false
})
export class HasPermissionDirective {
  private permissionCodes: string | string[] = [];

  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
    private authService: AuthService
  ) {}

  @Input() set appHasPermission(codes: string | string[]) {
    this.permissionCodes = codes;
    this.updateView();
  }

  private updateView(): void {
    this.viewContainer.clear();

    const hasPermission = Array.isArray(this.permissionCodes)
      ? this.authService.hasAnyPermission(this.permissionCodes)
      : this.authService.hasPermission(this.permissionCodes);

    if (hasPermission) {
      this.viewContainer.createEmbeddedView(this.templateRef);
    }
  }
}
