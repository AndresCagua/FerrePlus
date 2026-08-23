import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { Contacto } from '../../models/contacto';
import { TalentoService } from '../../services/talento.service';
import { mensajeTalento } from '../../shared/talento-error.mapper';

@Component({ selector: 'app-contactos', templateUrl: './contactos.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class ContactosComponent implements OnInit {
  contactos: Contacto[] = []; loading = false; loaded = false; error = '';
  constructor(private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.load(); }
  load(): void { this.loading = true; this.error = ''; this.service.listarContactos().subscribe({ next: d => { this.contactos = d; this.loaded = true; this.loading = false; this.cdr.markForCheck(); }, error: e => { this.error = mensajeTalento(e); this.loading = false; this.cdr.markForCheck(); } }); }
  mark(contacto: Contacto): void { this.service.marcarContacto(contacto.id, contacto.estado === 'READ' ? 'UNREAD' : 'READ').subscribe({ next: () => this.load(), error: e => { this.error = mensajeTalento(e); this.cdr.markForCheck(); } }); }
}
