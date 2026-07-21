import { ChangeDetectionStrategy, Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { ChartConfiguration, ChartType } from 'chart.js';
import { DashboardService } from '../dashboard.service';
import { DashboardData } from '../../core/models';

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
    { key: 'totalProductos', label: 'Total Productos', icon: 'inventory_2', color: '#1565C0' },
    { key: 'productosStockBajo', label: 'Stock Bajo', icon: 'warning_amber', color: '#c62828' },
    { key: 'ventasHoy', label: 'Ventas Hoy', icon: 'today', color: '#2e7d32' },
    { key: 'ventasMes', label: 'Ventas del Mes', icon: 'date_range', color: '#FF8F00' },
    { key: 'totalClientes', label: 'Total Clientes', icon: 'people', color: '#6a1b9a' },
    { key: 'totalProveedores', label: 'Proveedores', icon: 'local_shipping', color: '#00838f' }
  ];

  constructor(
    private dashboardService: DashboardService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadDashboard();
  }

  private detectChanges(): void {
    try { this.cdr.detectChanges(); } catch(e) {}
  }

  loadDashboard(): void {
    this.loading = true;
    this.error = false;
    this.dashboardService.getDashboardData().subscribe({
      next: (data) => {
        this.data = data;
        this.loading = false;
        this.detectChanges();
      },
      error: () => {
        this.loading = false;
        this.error = true;
        this.detectChanges();
      }
    });
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
