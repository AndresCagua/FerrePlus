import { ChangeDetectionStrategy, Component, EventEmitter, Output } from '@angular/core';

@Component({
  selector: 'app-indisponibilidad-talento',
  template: `<div class="alert alert-warning" role="alert" aria-live="polite">
    <strong>{{ mensaje }}</strong>
    <button type="button" class="btn btn-link" (click)="retry.emit()">Reintentar</button>
  </div>`,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false
})
export class IndisponibilidadTalentoComponent {
  @Output() retry = new EventEmitter<void>();
  readonly mensaje = 'Servicio de postulaciones temporalmente no disponible';
}
