import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { TalentoService } from './talento.service';

describe('TalentoService', () => {
  let service: TalentoService;
  let http: HttpTestingController;
  beforeEach(() => { TestBed.configureTestingModule({ providers: [TalentoService, provideHttpClient(), provideHttpClientTesting()] }); service = TestBed.inject(TalentoService); http = TestBed.inject(HttpTestingController); });
  afterEach(() => http.verify());
  it('consume solo el contrato de admin-api para convocatorias', () => { service.listarConvocatorias().subscribe(); const request = http.expectOne(r => r.url.endsWith('/api/admin/talento/convocatorias')); expect(request.request.method).toBe('GET'); request.flush([]); });
  it('descarga el CV como blob mediante el proxy autenticado', () => { service.descargarCv('p-1').subscribe(result => expect(result).toBeInstanceOf(Blob)); const request = http.expectOne(r => r.url.endsWith('/api/admin/talento/postulaciones/p-1/cv')); expect(request.request.responseType).toBe('blob'); request.flush(new Blob(['cv'])); });
});
