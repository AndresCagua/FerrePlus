import { Injectable } from '@angular/core';
import {
  CanActivate,
  Router,
  ActivatedRouteSnapshot,
  RouterStateSnapshot
} from '@angular/router';
import { AuthService } from './auth.service';

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
  ): boolean {
    if (!this.authService.isLoggedIn()) {
      this.router.navigate(['/auth'], {
        queryParams: { returnUrl: state.url }
      });
      return false;
    }

    const roles = route.data?.['roles'] as string[] | undefined;
    if (roles && roles.length > 0) {
      const hasRole = this.authService.hasAnyRole(roles);
      if (!hasRole) {
        this.router.navigate(['/dashboard']);
        return false;
      }
    }

    return true;
  }
}
