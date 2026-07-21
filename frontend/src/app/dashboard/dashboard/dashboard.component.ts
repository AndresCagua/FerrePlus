import { ChangeDetectionStrategy, Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { ChartConfiguration, ChartType } from 'chart.js';
import { DashboardService } from '../dashboard.service';
import { DashboardData } from '../../core/models';

type Periodo = 'week' | 'month' | 'year';

@Component({
  selector: 'app-dashboard',
  standalone: false,
  changeDetection: ChangeDetectionStrategy.Eager,
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  data: DashboardData | null = null;
  loading = true;
  error = false;

  // Period filter
  periodo: Periodo = 'month';
  periodoLabel = 'Este Mes';
  totalPeriodo = 0;
  loadingChart = false;

  // Chart configuration
  barChartType: ChartType = 'bar';
  barChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: []
  };
  barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
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

  metrics = [
    { key: 'totalProductos', label: 'Total Productos', icon: 'inventory_2', color: '#1565C0', route: '/productos' },
    { key: 'productosStockBajo', label: 'Stock Bajo', icon: 'warning_amber', color: '#c62828', route: '/productos' },
    { key: 'ventasHoy', label: 'Ventas Hoy', icon: 'today', color: '#2e7d32', route: '/ventas' },
    { key: 'ventasMes', label: 'Ventas del Mes', icon: 'date_range', color: '#FF8F00', route: '/ventas' },
    { key: 'totalClientes', label: 'Total Clientes', icon: 'people', color: '#6a1b9a', route: '/clientes' },
    { key: 'totalProveedores', label: 'Proveedores', icon: 'local_shipping', color: '#00838f', route: '/proveedores' }
  ];

  constructor(
    private dashboardService: DashboardService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  navigateToMetric(metric: any): void {
    this.router.navigate([metric.route]);
  }

  ngOnInit(): void {
    this.loadDashboard();
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch(e) {}
  }

  private toDateStr(d: Date): string {
    return d.toISOString().split('T')[0];
  }

  private getDateRange(periodo: Periodo): { desde: string; hasta: string } {
    const hoy = new Date();
    const hasta = this.toDateStr(hoy);
    let desde: Date;

    switch (periodo) {
      case 'week': {
        const dia = hoy.getDay();
        const diff = dia === 0 ? 6 : dia - 1; // Monday as first day
        desde = new Date(hoy);
        desde.setDate(hoy.getDate() - diff);
        break;
      }
      case 'year':
        desde = new Date(hoy.getFullYear(), 0, 1);
        break;
      case 'month':
      default:
        desde = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
        break;
    }

    return { desde: this.toDateStr(desde), hasta };
  }

  setPeriodo(periodo: Periodo): void {
    this.periodo = periodo;
    const labels: Record<Periodo, string> = {
      week: 'Esta Semana',
      month: 'Este Mes',
      year: 'Este Año'
    };
    this.periodoLabel = labels[periodo];
    this.loadChartData();
  }

  loadDashboard(): void {
    this.loading = true;
    this.error = false;
    this.dashboardService.getDashboardData().subscribe({
      next: (data) => {
        this.data = data;
        this.loading = false;
        // Llamar loadChartData ANTES de detectChanges para que
        // loadingChart se actualice en el mismo ciclo y no dispare
        // ExpressionChangedAfterItHasBeenCheckedError
        this.loadChartData();
        this.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.error = true;
        this.detectChanges();
      }
    });
  }

  loadChartData(): void {
    this.loadingChart = true;
    const { desde, hasta } = this.getDateRange(this.periodo);

    this.dashboardService.getVentasPorDia(desde, hasta).subscribe({
      next: (ventas: any[]) => {
        this.buildChart(ventas);
        this.loadingChart = false;
        this.detectChanges();
      },
      error: () => {
        this.barChartData = { labels: [], datasets: [] };
        this.totalPeriodo = 0;
        this.loadingChart = false;
        this.detectChanges();
      }
    });
  }

  private buildChart(ventas: any[]): void {
    const groupBy = this.periodo === 'year' ? 'month' : 'day';
    const totals = new Map<string, number>();
    let granTotal = 0;

    for (const v of ventas) {
      const fecha = v.fechaCreacion ? v.fechaCreacion.split('T')[0] : '';
      if (!fecha) continue;
      const total = Number(v.total || 0);
      granTotal += total;

      if (groupBy === 'month') {
        const mesKey = fecha.substring(0, 7); // YYYY-MM
        totals.set(mesKey, (totals.get(mesKey) || 0) + total);
      } else {
        totals.set(fecha, (totals.get(fecha) || 0) + total);
      }
    }

    this.totalPeriodo = granTotal;

    const sorted = [...totals.entries()].sort(([a], [b]) => a.localeCompare(b));

    this.barChartData = {
      labels: sorted.map(([key]) => {
        const d = new Date(key + (groupBy === 'month' ? '-01T12:00:00' : 'T12:00:00'));
        if (groupBy === 'month') {
          return d.toLocaleDateString('es-ES', { month: 'short' });
        }
        return d.toLocaleDateString('es-ES', { weekday: 'short', day: 'numeric', month: 'short' });
      }),
      datasets: [{
        data: sorted.map(([_, total]) => total),
        label: 'Ventas',
        backgroundColor: '#42A5F5',
        borderRadius: 6,
        maxBarThickness: groupBy === 'month' ? 60 : 40
      }]
    };
  }

  getMetricValue(key: string): number | string {
    if (!this.data) return 0;
    const value = (this.data as any)[key];
    if (key === 'ventasHoy' || key === 'ventasMes' || key === 'totalVentasHoy' || key === 'totalVentasMes') {
      return this.formatCurrency(value || 0);
    }
    return value ?? 0;
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
