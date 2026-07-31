import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { RUTAS_POR_PERMISO } from '../../core/rutas-por-permiso';

@Component({
  selector: 'app-login',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  loading = false;
  errorMessage = '';
  hidePassword = true;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private route: ActivatedRoute,
    private cdr: ChangeDetectorRef
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(4)]]
    });
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch { /* noop */ }
  }

  ngOnInit(): void {
    if (this.authService.isLoggedIn()) {
      const destination = this.getInitialDestination();
      if (destination) {
        this.router.navigateByUrl(destination);
      } else {
        // Logueado pero sin NINGUNA ruta accesible: quedarse en /auth con
        // mensaje claro (no redirigir a /dashboard → guard → bucle).
        this.errorMessage = 'Tu usuario no tiene permisos asignados. Contacta al administrador.';
        this.detectChanges();
      }
    }
  }

  onSubmit(): void {
    if (this.loginForm.invalid) {
      return;
    }

    this.loading = true;
    this.errorMessage = '';
    this.detectChanges();

    const { email, password } = this.loginForm.value;

    this.authService.login(email, password).subscribe({
      next: () => {
        const destination = this.getInitialDestination();
        if (!destination) {
          this.loading = false;
          this.errorMessage = 'Tu usuario no tiene permisos asignados. Contacta al administrador.';
          this.detectChanges();
          return;
        }

        this.router.navigateByUrl(destination).then(navigated => {
          if (!navigated) {
            console.error(`No se pudo navegar a ${destination}`);
            this.loading = false;
            this.errorMessage = 'Error al cargar la aplicación. Intenta de nuevo.';
            this.detectChanges();
          }
        });
      },
      error: (error) => {
        this.loading = false;
        if (error.status === 401) {
          this.errorMessage = 'Credenciales incorrectas. Verifica tu email y contraseña.';
        } else if (error.status === 0) {
          this.errorMessage = 'Error de conexión. Verifica que el servidor esté funcionando.';
        } else {
          this.errorMessage = error.error?.message || 'Ocurrió un error al iniciar sesión.';
        }
        this.detectChanges();
      }
    });
  }

  /**
   * Destino post-login: respeta `returnUrl` (enviado por el guard al redirigir
   * a /auth) SOLO si el usuario tiene permiso para esa ruta; en caso contrario
   * cae a `AuthService.getHomeRoute()` (primera ruta permitida). Retorna null
   * si el usuario no tiene ninguna ruta accesible.
   */
  private getInitialDestination(): string | null {
    const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl');
    if (returnUrl) {
      const match = RUTAS_POR_PERMISO.find(
        item => returnUrl === item.route || returnUrl.startsWith(`${item.route}/`)
      );
      if (match && this.authService.hasAnyPermission(match.permissions ?? [])) {
        return returnUrl;
      }
    }
    return this.authService.getHomeRoute();
  }
}
