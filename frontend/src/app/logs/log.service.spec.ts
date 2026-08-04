import { TestBed } from '@angular/core/testing';
import {
  HttpClientTestingModule,
  HttpTestingController
} from '@angular/common/http/testing';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { LogService } from './log.service';
import { environment } from '../../environments/environment';
import { AuditoriaLog, EliminarLogsResponse, Page } from '../core/models';
import { UsuarioOpcion } from './log.service';

describe('LogService (contrato GET /api/logs + DELETE /api/logs)', () => {
  let service: LogService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [LogService]
    });
    service = TestBed.inject(LogService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('list arma el query con page/size y todos los filtros presentes', () => {
    const pageMock: Page<AuditoriaLog> = {
      content: [],
      totalElements: 0,
      totalPages: 0,
      size: 10,
      number: 2,
      first: false,
      last: true
    };

    let received: Page<AuditoriaLog> | undefined;
    service
      .list({
        page: 2,
        size: 10,
        fechaDesde: '2026-01-01',
        fechaHasta: '2026-01-31',
        usuarioId: 5,
        entidad: 'VENTA',
        accion: 'CREAR'
      })
      .subscribe(p => {
        received = p;
      });

    const req = httpMock.expectOne(r => r.method === 'GET' && r.url === `${environment.apiUrl}/logs`);
    expect(req.request.params.get('page')).toBe('2');
    expect(req.request.params.get('size')).toBe('10');
    expect(req.request.params.get('fechaDesde')).toBe('2026-01-01');
    expect(req.request.params.get('fechaHasta')).toBe('2026-01-31');
    expect(req.request.params.get('usuarioId')).toBe('5');
    expect(req.request.params.get('entidad')).toBe('VENTA');
    expect(req.request.params.get('accion')).toBe('CREAR');
    req.flush(pageMock);

    expect(received).toEqual(pageMock);
  });

  it('list omite los filtros vacíos del query string', () => {
    service.list({ page: 0, size: 20 }).subscribe();

    const req = httpMock.expectOne(r => r.method === 'GET' && r.url === `${environment.apiUrl}/logs`);
    expect(req.request.params.get('page')).toBe('0');
    expect(req.request.params.get('size')).toBe('20');
    expect(req.request.params.has('fechaDesde')).toBe(false);
    expect(req.request.params.has('fechaHasta')).toBe(false);
    expect(req.request.params.has('usuarioId')).toBe(false);
    expect(req.request.params.has('entidad')).toBe(false);
    expect(req.request.params.has('accion')).toBe(false);
    req.flush({ content: [], totalElements: 0, totalPages: 0, size: 20, number: 0 });
  });

  it('list omite usuarioId cuando es null o undefined', () => {
    service.list({ page: 0, size: 20, usuarioId: null }).subscribe();
    let req = httpMock.expectOne(r => r.method === 'GET' && r.url === `${environment.apiUrl}/logs`);
    expect(req.request.params.has('usuarioId')).toBe(false);
    req.flush({ content: [], totalElements: 0, totalPages: 0, size: 20, number: 0 });

    service.list({ page: 1, size: 20, usuarioId: undefined }).subscribe();
    req = httpMock.expectOne(r => r.method === 'GET' && r.url === `${environment.apiUrl}/logs`);
    expect(req.request.params.has('usuarioId')).toBe(false);
    req.flush({ content: [], totalElements: 0, totalPages: 0, size: 20, number: 1 });
  });

  it('listarUsuarios llama GET /logs/usuarios', () => {
    const usuariosMock: UsuarioOpcion[] = [{ id: 1, nombre: 'Admin' }];
    let received: UsuarioOpcion[] | undefined;
    service.listarUsuarios().subscribe(u => { received = u; });

    const req = httpMock.expectOne(r => r.method === 'GET' && r.url === `${environment.apiUrl}/logs/usuarios`);
    req.flush(usuariosMock);
    expect(received).toEqual(usuariosMock);
  });

  it('deleteByRange llama DELETE /logs con desde y hasta', () => {
    const resp: EliminarLogsResponse = { eliminados: 7 };
    let received: EliminarLogsResponse | undefined;
    service.deleteByRange('2026-01-01', '2026-01-31').subscribe(r => {
      received = r;
    });

    const req = httpMock.expectOne(r => r.method === 'DELETE' && r.url === `${environment.apiUrl}/logs`);
    expect(req.request.params.get('desde')).toBe('2026-01-01');
    expect(req.request.params.get('hasta')).toBe('2026-01-31');
    req.flush(resp);

    expect(received).toEqual(resp);
  });
});
