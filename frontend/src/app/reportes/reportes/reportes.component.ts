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
  reportType = 'ventas';

  // Charts
  ventasChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: []
  };
  ventasChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: true } }
  };

  topProductos: any[] = [];
  loadingReport = false;

  constructor(
    private fb: FormBuilder,
    private http: HttpClient
  ) {
    this.form = this.fb.group({
      fechaInicio: [''],
      fechaFin: [''],
      tipo: ['ventas']
    });
  }

  ngOnInit(): void {
    this.loadReport();
  }

  loadReport(): void {
    this.loadingReport = true;
    const apiUrl = environment.apiUrl;
    const params = this.form.value;

    switch (this.reportType) {
      case 'ventas':
        this.http.get<any>(`${apiUrl}/reportes/ventas`, { params }).subscribe({
          next: (data) => {
            this.buildVentasChart(data);
            this.loadingReport = false;
          },
          error: () => this.loadingReport = false
        });
        break;

      case 'top-productos':
        this.http.get<any[]>(`${apiUrl}/reportes/top-productos`, { params }).subscribe({
          next: (data) => {
            this.topProductos = data;
            this.buildTopProductosChart(data);
            this.loadingReport = false;
          },
          error: () => this.loadingReport = false
        });
        break;

      default:
        this.loadingReport = false;
    }
  }

  private buildVentasChart(data: any): void {
    const ventas = data.ventasPorDia || [];
    this.ventasChartData = {
      labels: ventas.map((v: any) => {
        const d = new Date(v.fecha);
        return d.toLocaleDateString('es-ES', { day: 'numeric', month: 'short' });
      }),
      datasets: [
        {
          label: 'Ventas',
          data: ventas.map((v: any) => v.total),
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

  setReportType(type: string): void {
    this.reportType = type;
    this.loadReport();
  }

  formatCurrency(value: number): string {
    return `$${value.toFixed(2)}`;
  }
}
