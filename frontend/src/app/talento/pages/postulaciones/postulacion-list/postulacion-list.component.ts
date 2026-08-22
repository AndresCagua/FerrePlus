import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Postulacion, PostulacionEstado } from '../../../models/postulacion';
import { TalentoService } from '../../../services/talento.service';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

@Component({ selector: 'app-postulacion-list', templateUrl: './postulacion-list.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PostulacionListComponent implements OnInit {
  postulaciones: Postulacion[] = []; convocatoriaId = ''; estado?: PostulacionEstado; loading = false; loaded = false; error = '';
  constructor(private readonly route: ActivatedRoute, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void {
    this.route.queryParamMap.subscribe(params => {
      this.convocatoriaId = params.get('convocatoriaId') ?? '';
      this.postulaciones = [];
      this.loaded = false;
      this.error = this.convocatoriaId ? '' : 'Selecciona una convocatoria para consultar postulaciones.';
      if (this.convocatoriaId) this.load();
      this.cdr.markForCheck();
    });
  }
  load(): void { if (!this.convocatoriaId) return; this.loading = true; this.error = ''; this.service.listarPostulaciones(this.convocatoriaId, this.estado).subscribe({ next: d => { this.postulaciones = d; this.loaded = true; this.loading = false; this.cdr.markForCheck(); }, error: e => { this.error = mensajeTalento(e); this.loading = false; this.cdr.markForCheck(); } }); }
}
