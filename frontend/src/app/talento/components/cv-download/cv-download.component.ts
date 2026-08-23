import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input } from '@angular/core';
import { TalentoService } from '../../services/talento.service';
import { mensajeTalento } from '../../shared/talento-error.mapper';

@Component({
  selector: 'app-cv-download',
  template: `<button class="btn btn-outline-primary btn-sm" type="button" [disabled]="loading" (click)="download()">
    {{ loading ? 'Descargando...' : 'Descargar CV' }}
  </button>
  <div *ngIf="error" class="alert alert-danger mt-2" role="alert" aria-live="assertive">
    <span>{{ error }}</span>
    <button type="button" class="btn btn-link p-0 ms-2" (click)="download()">Reintentar</button>
  </div>`,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false
})
export class CvDownloadComponent {
  @Input({ required: true }) postulacionId!: string;
  loading = false;
  error = '';

  constructor(private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}

  download(): void {
    this.loading = true;
    this.error = '';
    this.service.descargarCv(this.postulacionId).subscribe({
      next: blob => {
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.download = 'cv-postulacion';
        anchor.click();
        URL.revokeObjectURL(url);
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: error => {
        this.loading = false;
        this.error = mensajeTalento(error);
        this.cdr.markForCheck();
      }
    });
  }
}
