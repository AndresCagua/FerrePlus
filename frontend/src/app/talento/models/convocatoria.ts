export type ConvocatoriaEstado = 'DRAFT' | 'PUBLISHED' | 'CLOSED';

export interface Convocatoria {
  id: string;
  titulo: string;
  descripcion: string;
  requisitos: string[];
  ubicacion: string;
  modalidad: string;
  fechaApertura: string;
  fechaCierre: string;
  estado: ConvocatoriaEstado;
}

export type ConvocatoriaPayload = Omit<Convocatoria, 'id' | 'estado'> & { estado?: ConvocatoriaEstado };
