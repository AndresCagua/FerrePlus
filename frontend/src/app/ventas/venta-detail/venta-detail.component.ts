import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import Swal from 'sweetalert2';
import { VentaService } from '../venta.service';
import { Venta } from '../../core/models';

@Component({
  selector: 'app-venta-detail',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './venta-detail.component.html',
  styleUrls: ['./venta-detail.component.scss']
})
export class VentaDetailComponent implements OnInit {
  venta: Venta | null = null;
  loading = true;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ventaService: VentaService,
    private cdr: ChangeDetectorRef
  ) {}

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch { /* noop */ }
  }

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (id) {
      this.loadVenta(id);
    } else {
      this.router.navigate(['/ventas']);
    }
  }

  loadVenta(id: number): void {
    this.loading = true;
    this.ventaService.getById(id).subscribe({
      next: (venta) => {
        this.venta = venta;
        this.loading = false;
        this.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.detectChanges();
        Swal.fire('Error', 'No se pudo cargar la venta', 'error');
        this.router.navigate(['/ventas']);
      }
    });
  }

  anular(): void {
    if (!this.venta) return;
    Swal.fire({
      title: '¿Anular venta?',
      text: `Se anulará la factura ${this.venta.numeroFactura}`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#c62828',
      cancelButtonColor: '#78909c',
      confirmButtonText: 'Sí, anular',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.ventaService.anular(this.venta!.id).subscribe({
          next: () => {
            Swal.fire('Anulada', 'Venta anulada correctamente', 'success');
            this.loadVenta(this.venta!.id);
          },
          error: () => {
            this.detectChanges();
            Swal.fire('Error', 'No se pudo anular la venta', 'error');
          }
        });
      }
    });
  }

  printInvoice(): void {
    window.print();
  }

  goBack(): void {
    this.router.navigate(['/ventas']);
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
