export type PostulacionEstado = 'RECEIVED' | 'UNDER_REVIEW' | 'ACCEPTED' | 'REJECTED';

export interface HistorialPostulacion {
  actor: string;
  fecha: string;
  anterior: PostulacionEstado;
  nuevo: PostulacionEstado;
}

export interface CvMetadata {
  fileName: string;
  mimeType: string;
  size: number;
  createdAt: string;
}

export interface Postulacion {
  id: string;
  convocatoriaId: string;
  nombres: string;
  apellidos: string;
  email: string;
  telefono: string;
  ciudad: string;
  estado: PostulacionEstado;
  cv?: CvMetadata;
  historial: HistorialPostulacion[];
  createdAt: string;
}
