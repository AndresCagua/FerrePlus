import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Publicacion } from '../../../models/publicacion';
import { TalentoService } from '../../../services/talento.service';
import { mensajeTalento } from '../../../shared/talento-error.mapper';

const SAFE_MEDIA_KEY = /^[0-9a-fA-F-]{36}\.(jpg|png|webp)$/;

export function portadaMediaUrl(portada: Publicacion['portada']): string | null {
  const objectKey = portada?.objectKey;
  return objectKey && SAFE_MEDIA_KEY.test(objectKey) ? `/media/${encodeURIComponent(objectKey)}` : null;
}

@Component({ selector: 'app-publicacion-list', templateUrl: './publicacion-list.component.html', styleUrls: ['./publicacion-list.component.scss'], changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class PublicacionListComponent implements OnInit {
  publicaciones: Publicacion[] = []; loading = false; error = ''; loaded = false;
  readonly failedPortadas = new Set<string>();
  constructor(private readonly service: TalentoService, private readonly router: Router, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.load(); }
  load(): void { this.loading = true; this.error = ''; this.service.listarPublicaciones().subscribe({ next: data => { this.publicaciones = data; this.loaded = true; this.loading = false; this.cdr.markForCheck(); }, error: err => { this.error = mensajeTalento(err); this.loading = false; this.cdr.markForCheck(); } }); }
  state(id: string, estado: 'DRAFT' | 'PUBLISHED'): void { this.service.cambiarEstadoPublicacion(id, estado).subscribe({ next: () => this.load(), error: err => { this.error = mensajeTalento(err); this.cdr.markForCheck(); } }); }
  delete(id: string): void { this.service.eliminarPublicacion(id).subscribe({ next: () => this.load(), error: err => { this.error = mensajeTalento(err); this.cdr.markForCheck(); } }); }
  portadaUrl(item: Publicacion): string | null { return this.failedPortadas.has(item.id) ? null : portadaMediaUrl(item.portada); }
  portadaFailed(item: Publicacion): void { this.failedPortadas.add(item.id); this.cdr.markForCheck(); }
}
