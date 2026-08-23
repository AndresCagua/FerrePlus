import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CommonModule } from '@angular/common';
import { describe, expect, it, beforeEach, vi } from 'vitest';
import { throwError } from 'rxjs';
import { CvDownloadComponent } from './cv-download.component';
import { TalentoService } from '../../services/talento.service';

describe('CvDownloadComponent', () => {
  let fixture: ComponentFixture<CvDownloadComponent>;
  let component: CvDownloadComponent;
  let downloadMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    downloadMock = vi.fn();

    TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [CvDownloadComponent],
      providers: [{ provide: TalentoService, useValue: { descargarCv: downloadMock } }]
    });

    fixture = TestBed.createComponent(CvDownloadComponent);
    component = fixture.componentInstance;
    component.postulacionId = 'p-1';
  });

  it('muestra un error visible y permite reintentar cuando falla la descarga', () => {
    downloadMock.mockReturnValue(throwError(() => new Error('network failure')));
    fixture.detectChanges();

    component.download();
    fixture.detectChanges();

    const alert = fixture.nativeElement.querySelector('[role="alert"]') as HTMLElement;
    const retry = alert.querySelector('button') as HTMLButtonElement;

    expect(alert.textContent).toContain('Servicio de postulaciones temporalmente no disponible');
    expect(retry.textContent).toContain('Reintentar');
    expect(retry.disabled).toBe(false);

    downloadMock.mockReturnValue(throwError(() => new Error('still failing')));
    retry.click();

    expect(downloadMock).toHaveBeenCalledTimes(2);
  });
});
