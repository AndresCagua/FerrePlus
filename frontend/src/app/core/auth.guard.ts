import { Injectable } from '@angular/core';
import {
  CanActivate,
  Router,
  ActivatedRouteSnapshot,
  RouterStateSnapshot
} from '@angular/router';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { AuthService } from './auth.service';

/**
 * Guard de autenticación y permisos (R7):
 *  - Sin token → redirect a `/auth` con `returnUrl`.
 *  - Con token → refresh de permisos vía `GET /api/usuarios/me` en CADA
 *    navegación (Decisión 6): los cambios de rol/overrides aplican sin re-login.
 *  - Si `route.data.permissions` está presente → `hasAnyPermission`; si no la
 *    cumple, redirect a la PRIMERA ruta permitida del usuario
 *    (`AuthService.getHomeRoute()`), no al dashboard hardcodeado.
 *  - Si el usuario no tiene NINGUNA ruta accesible → logout + redirect a `/auth`.
 *  - Se conserva el chequeo de `data.roles` para compatibilidad transitoria.
 *  - Si el refresh falla → redirect a `/auth` y bloquea.
 */
@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): Observable<boolean> {
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/auth'], {
        queryParams: { returnUrl: state.url }
      });
      return of(false);
    }

    return this.authService.refreshPermisos().pipe(
      map(() => {
        const permissions = route.data?.['permissions'] as string[] | undefined;
        if (permissions && permissions.length > 0) {
          if (!this.authService.hasAnyPermission(permissions)) {
            this.redirectToHome(state);
            return false;
          }
          return true;
        }

        // Compatibilidad transitoria con data.roles.
        const roles = route.data?.['roles'] as string[] | undefined;
        if (roles && roles.length > 0) {
          if (!this.authService.hasAnyRole(roles)) {
            this.redirectToHome(state);
            return false;
          }
        }

        return true;
      }),
      catchError(() => {
        this.router.navigate(['/auth'], {
          queryParams: { returnUrl: state.url }
        });
        return of(false);
      })
    );
  }

  /**
   * Redirige a la primera ruta que el usuario SÍ puede ver. Si el usuario no
   * tiene ninguna página accesible, cierra sesión y vuelve al login (evita
   * el "sistema bloqueado": usuario logueado sin ninguna ruta disponible).
   */
  private redirectToHome(state: RouterStateSnapshot): void {
    const homeRoute = this.authService.getHomeRoute();

    if (homeRoute === null) {
      this.authService.logout();
      this.router.navigate(['/auth']);
      return;
    }

    // Evita el bucle de redirección si la ruta destino ya es el home.
    if (state.url !== homeRoute) {
      this.router.navigateByUrl(homeRoute);
    }
  }
}
