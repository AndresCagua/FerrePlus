import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Publicacion } from '../../../models/publicacion';
import { TalentoService } from '../../../services/talento.service';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

@Component({ selector: 'app-publicacion-list', templateUrl: './publicacion-list.component.html', styleUrls: ['./publicacion-list.component.scss'], changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PublicacionListComponent implements OnInit {
  publicaciones: Publicacion[] = []; loading = false; error = ''; loaded = false;
  constructor(private readonly service: TalentoService, private readonly router: Router, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.load(); }
  load(): void { this.loading = true; this.error = ''; this.service.listarPublicaciones().subscribe({ next: data => { this.publicaciones = data; this.loaded = true; this.loading = false; this.cdr.markForCheck(); }, error: err => { this.error = mensajeTalento(err); this.loading = false; this.cdr.markForCheck(); } }); }
  state(id: string, estado: 'DRAFT' | 'PUBLISHED'): void { this.service.cambiarEstadoPublicacion(id, estado).subscribe({ next: () => this.load(), error: err => { this.error = mensajeTalento(err); this.cdr.markForCheck(); } }); }
  delete(id: string): void { this.service.eliminarPublicacion(id).subscribe({ next: () => this.load(), error: err => { this.error = mensajeTalento(err); this.cdr.markForCheck(); } }); }
}
