import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { ChartConfiguration } from 'chart.js';

@Component({
  selector: 'app-reportes',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './reportes.component.html',
  styleUrls: ['./reportes.component.scss']
})
export class ReportesComponent implements OnInit {
  form: FormGroup;
  loading = false;
  reportType: 'ventas' | 'top-productos' = 'ventas';

  // Charts
  ventasChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: []
  };
  ventasChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: true },
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

  topProductos: any[] = [];
  loadingReport = false;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient,
    private cdr: ChangeDetectorRef
  ) {
    const hoy = new Date();
    const inicioMes = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
    this.form = this.fb.group({
      desde: [this.toDateString(inicioMes)],
      hasta: [this.toDateString(hoy)]
    });
  }

  private toDateString(d: Date): string {
    return d.toISOString().split('T')[0];
  }

  ngOnInit(): void {
    this.loadReport();
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch(e) { /* noop */ }
  }

  loadReport(): void {
    this.loadingReport = true;
    this.detectChanges();

    const apiUrl = environment.apiUrl;
    const params = this.form.value;

    switch (this.reportType) {
      case 'ventas':
        this.http.get<any[]>(`${apiUrl}/reportes/ventas`, { params }).subscribe({
          next: (data) => {
            this.buildVentasChart(data);
            this.loadingReport = false;
            this.detectChanges();
          },
          error: () => {
            this.loadingReport = false;
            this.detectChanges();
          }
        });
        break;

      case 'top-productos':
        this.http.get<any[]>(`${apiUrl}/reportes/top-productos`, { params }).subscribe({
          next: (data) => {
            this.topProductos = data;
            this.buildTopProductosChart(data);
            this.loadingReport = false;
            this.detectChanges();
          },
          error: () => {
            this.loadingReport = false;
            this.detectChanges();
          }
        });
        break;

      default:
        this.loadingReport = false;
        this.detectChanges();
    }
  }

  private buildVentasChart(ventas: any[]): void {
    // Group by day and sum totals
    const dailyTotals = new Map<string, number>();
    for (const v of ventas) {
      const day = v.fechaCreacion ? v.fechaCreacion.split('T')[0] : '';
      if (!day) continue;
      dailyTotals.set(day, (dailyTotals.get(day) || 0) + Number(v.total || 0));
    }

    // Sort by date
    const sorted = [...dailyTotals.entries()].sort(([a], [b]) => a.localeCompare(b));

    this.ventasChartData = {
      labels: sorted.map(([fecha]) => {
        const d = new Date(fecha + 'T12:00:00');
        return d.toLocaleDateString('es-ES', { day: 'numeric', month: 'short' });
      }),
      datasets: [
        {
          label: 'Ventas ($)',
          data: sorted.map(([_, total]) => total),
          backgroundColor: '#42A5F5',
          borderRadius: 6
        }
      ]
    };
  }

  private buildTopProductosChart(data: any[]): void {
    this.ventasChartData = {
      labels: data.slice(0, 10).map(p => p.nombre),
      datasets: [
        {
          label: 'Cantidad Vendida',
          data: data.slice(0, 10).map(p => p.cantidad),
          backgroundColor: '#FF8F00',
          borderRadius: 6
        }
      ]
    };
  }

  setReportType(type: 'ventas' | 'top-productos'): void {
    this.reportType = type;
    this.loadReport();
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
