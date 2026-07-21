import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { MatDialog } from '@angular/material/dialog';
import { ChartConfiguration, ChartType } from 'chart.js';
import { forkJoin } from 'rxjs';
import { PrecioService } from '../precio.service';
import { PrecioProducto, HistoricoPrecioProducto } from '../../core/models';
import { ActualizarPrecioDialog } from '../actualizar-precio-dialog/actualizar-precio-dialog.component';

@Component({
  selector: 'app-precio-detail',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './precio-detail.component.html',
  styleUrls: ['./precio-detail.component.scss']
})
export class PrecioDetailComponent implements OnInit {
  productoId!: number;
  precio: PrecioProducto | null = null;
  historial: HistoricoPrecioProducto[] = [];
  loading = true;
  error = false;

  // Chart configuration
  lineChartType: ChartType = 'line';
  lineChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: []
  };
  lineChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top'
      },
      tooltip: {
        callbacks: {
          label: (context) => `$${context.parsed.y?.toFixed(2) ?? '0.00'}`
        }
      }
    },
    scales: {
      x: {
        grid: { display: false }
      },
      y: {
        beginAtZero: true,
        ticks: {
          callback: (value) => `$${value}`
        }
      }
    }
  };

  // Table columns for historial
  historialColumns: string[] = ['fechaCambio', 'tipoCambio', 'precioCompra', 'precioVenta', 'referencia', 'usuarioNombre'];

  constructor(
    private precioService: PrecioService,
    private route: ActivatedRoute,
    private router: Router,
    private cdr: ChangeDetectorRef,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.productoId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadData();
  }

  loadData(): void {
    this.loading = true;
    forkJoin({
      precio: this.precioService.getById(this.productoId),
      historial: this.precioService.getHistorial(this.productoId)
    }).subscribe({
      next: (result) => {
        this.precio = result.precio;
        this.historial = result.historial;
        this.buildChart(result.historial);
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.error = true;
        this.cdr.detectChanges();
      }
    });
  }

  private buildChart(historial: HistoricoPrecioProducto[]): void {
    if (historial.length === 0) {
      this.lineChartData = { labels: [], datasets: [] };
      return;
    }

    // Sort ascending for chronological chart
    const sorted = [...historial].sort(
      (a, b) => new Date(a.fechaCambio).getTime() - new Date(b.fechaCambio).getTime()
    );

    this.lineChartData = {
      labels: sorted.map(h => {
        const d = new Date(h.fechaCambio);
        return d.toLocaleDateString('es-ES', { day: 'numeric', month: 'short', year: 'numeric' });
      }),
      datasets: [
        {
          data: sorted.map(h => h.precioCompra),
          label: 'Precio Compra',
          borderColor: '#1565C0',
          backgroundColor: 'rgba(21, 101, 192, 0.1)',
          fill: false,
          tension: 0.3
        },
        {
          data: sorted.map(h => h.precioVenta),
          label: 'Precio Venta',
          borderColor: '#2e7d32',
          backgroundColor: 'rgba(46, 125, 50, 0.1)',
          fill: false,
          tension: 0.3
        }
      ]
    };
  }

  openActualizarDialog(): void {
    const dialogRef = this.dialog.open(ActualizarPrecioDialog, {
      width: '450px',
      data: {
        productoId: this.productoId,
        precioCompraActual: this.precio?.precioCompra ?? 0
      }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadData();
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/gestion-precios']);
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
