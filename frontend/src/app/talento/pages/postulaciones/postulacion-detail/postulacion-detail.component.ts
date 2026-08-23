import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Postulacion, PostulacionEstado } from '../../../models/postulacion';
import { TalentoService } from '../../../services/talento.service';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

@Component({ selector: 'app-postulacion-detail', templateUrl: './postulacion-detail.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PostulacionDetailComponent implements OnInit {
  postulacion?: Postulacion; loading = true; error = ''; readonly estados: PostulacionEstado[] = ['UNDER_REVIEW', 'ACCEPTED', 'REJECTED'];
  constructor(private readonly route: ActivatedRoute, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.load(); }
  load(): void { this.loading = true; this.service.obtenerPostulacion(this.route.snapshot.paramMap.get('id')!).subscribe({ next: p => { this.postulacion = p; this.loading = false; this.cdr.markForCheck(); }, error: e => { this.error = mensajeTalento(e); this.loading = false; this.cdr.markForCheck(); } }); }
  transition(estado: PostulacionEstado): void { if (!this.postulacion || !this.validTransition(estado)) return; this.service.cambiarEstadoPostulacion(this.postulacion.id, estado).subscribe({ next: p => { this.postulacion = p; this.cdr.markForCheck(); }, error: e => { this.error = mensajeTalento(e); this.cdr.markForCheck(); } }); }
  validTransition(next: PostulacionEstado): boolean { const current = this.postulacion?.estado; return current === 'RECEIVED' && next === 'UNDER_REVIEW' || current === 'UNDER_REVIEW' && (next === 'ACCEPTED' || next === 'REJECTED'); }
}
