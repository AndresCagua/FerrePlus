import { NgModule, APP_INITIALIZER } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { ReactiveFormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';
import { MatIconRegistry } from '@angular/material/icon';
import { provideCharts, withDefaultRegisterables } from 'ng2-charts';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { TokenInterceptor } from './core/token.interceptor';
import { SharedModule } from './shared/shared.module';

/**
 * Inicializa MatIconRegistry con el set de fuentes de Material Icons por defecto.
 * Sin esto, mat-icon en Angular 22 puede no renderizar los iconos de ligadura correctamente.
 */
export function configureIconRegistry(registry: MatIconRegistry): () => void {
  // Debe incluir 'mat-ligature-font' — el valor por defecto es ["material-icons", "mat-ligature-font"].
  // Sobrescribir sin esto rompe el renderizado de ligaduras y causa fallback a tres puntos.
  return () => registry.setDefaultFontSetClass('material-icons', 'mat-ligature-font');
}

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpClientModule,
    ReactiveFormsModule,
    AppRoutingModule,
    MatIconModule,
    SharedModule
  ],
  providers: [
    provideCharts(withDefaultRegisterables()),
    {
      provide: HTTP_INTERCEPTORS,
      useClass: TokenInterceptor,
      multi: true
    },
    {
      provide: APP_INITIALIZER,
      useFactory: configureIconRegistry,
      deps: [MatIconRegistry],
      multi: true
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
