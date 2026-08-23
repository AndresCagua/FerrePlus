import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { Destinatario, DestinatarioTipo } from '../../models/destinatario';
import { TalentoService } from '../../services/talento.service';
import { mensajeTalento } from '../../shared/talento-error.mapper';

@Component({ selector: 'app-destinatarios', templateUrl: './destinatarios.component.html', changeDetection: ChangeDetectionStrategy.OnPush, standalone: false })
export class DestinatariosComponent implements OnInit {
  destinatarios: Destinatario[] = []; loading = false; error = ''; readonly form = this.fb.group({ tipo: ['JOB_APPLICATION' as DestinatarioTipo, Validators.required], email: ['', [Validators.required, Validators.email]] });
  constructor(private readonly fb: FormBuilder, private readonly service: TalentoService, private readonly cdr: ChangeDetectorRef) {}
  ngOnInit(): void { this.load(); }
  load(): void { this.loading = true; this.service.listarDestinatarios().subscribe({ next: d => { this.destinatarios = d; this.loading = false; this.cdr.markForCheck(); }, error: e => { this.error = mensajeTalento(e); this.loading = false; this.cdr.markForCheck(); } }); }
  save(): void { if (this.form.invalid) return; this.service.crearDestinatario({ tipo: this.form.value.tipo!, email: this.form.value.email!, activo: true }).subscribe({ next: () => { this.form.reset({ tipo: 'JOB_APPLICATION', email: '' }); this.load(); }, error: e => { this.error = mensajeTalento(e); this.cdr.markForCheck(); } }); }
  toggle(item: Destinatario): void { this.service.actualizarDestinatario(item.id, { tipo: item.tipo, email: item.email, activo: !item.activo }).subscribe({ next: () => this.load(), error: e => { this.error = mensajeTalento(e); this.cdr.markForCheck(); } }); }
  remove(id: string): void { this.service.eliminarDestinatario(id).subscribe({ next: () => this.load(), error: e => { this.error = mensajeTalento(e); this.cdr.markForCheck(); } }); }
}
