import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Convocatoria } from '../../../models/convocatoria';
import { TalentoService } from '../../../services/talento.service';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

@Component({ selector: 'app-convocatoria-list', templateUrl: './convocatoria-list.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class ConvocatoriaListComponent implements OnInit {
  convocatorias: Convocatoria[] = []; loading = false; loaded = false; error = '';
  constructor(private readonly service: TalentoService, private readonly router: Router, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.load(); }
  load(): void { this.loading = true; this.error = ''; this.service.listarConvocatorias().subscribe({ next: d => { this.convocatorias = d; this.loaded = true; this.loading = false; this.cdr.markForCheck(); }, error: e => { this.error = mensajeTalento(e); this.loading = false; this.cdr.markForCheck(); } }); }
  state(id: string, estado: 'DRAFT' | 'PUBLISHED' | 'CLOSED'): void { this.service.cambiarEstadoConvocatoria(id, estado).subscribe({ next: () => this.load(), error: e => { this.error = mensajeTalento(e); this.cdr.markForCheck(); } }); }
}
