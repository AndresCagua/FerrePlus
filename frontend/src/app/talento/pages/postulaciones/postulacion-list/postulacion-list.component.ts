import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Convocatoria } from '../../../models/convocatoria';
import { Postulacion, PostulacionEstado } from '../../../models/postulacion';
import { TalentoService } from '../../../services/talento.service';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

@Component({ selector: 'app-postulacion-list', templateUrl: './postulacion-list.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PostulacionListComponent implements OnInit {
  postulaciones: Postulacion[] = [];
  convocatorias: Convocatoria[] = [];
  convocatoriaId = '';
  estado?: PostulacionEstado;
  loading = false;
  loadingConvocatorias = false;
  loaded = false;
  error = '';
  convocatoriasError = '';
  constructor(private readonly route: ActivatedRoute, private readonly router: Router, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void {
    this.loadConvocatorias();
    this.route.queryParamMap.subscribe(params => {
      this.convocatoriaId = params.get('convocatoriaId') ?? '';
      this.postulaciones = [];
      this.loaded = false;
      this.error = '';
      if (this.convocatoriaId) this.load();
      this.cdr.markForCheck();
    });
  }
  loadConvocatorias(): void {
    this.loadingConvocatorias = true;
    this.service.listarConvocatorias().subscribe({
      next: data => { this.convocatorias = data; this.loadingConvocatorias = false; this.cdr.markForCheck(); },
      error: e => { this.convocatoriasError = mensajeTalento(e); this.loadingConvocatorias = false; this.cdr.markForCheck(); },
    });
  }
  selectConvocatoria(id: string): void {
    this.router.navigate([], { relativeTo: this.route, queryParams: { convocatoriaId: id || null }, queryParamsHandling: 'merge' });
  }
  load(): void { if (!this.convocatoriaId) return; this.loading = true; this.error = ''; this.service.listarPostulaciones(this.convocatoriaId, this.estado).subscribe({ next: d => { this.postulaciones = d; this.loaded = true; this.loading = false; this.cdr.markForCheck(); }, error: e => { this.error = mensajeTalento(e); this.loading = false; this.cdr.markForCheck(); } }); }
}
