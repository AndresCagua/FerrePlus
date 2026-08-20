export type PublicacionEstado = 'DRAFT' | 'PUBLISHED';

export interface MetadataSeo {
  title: string;
  description: string;
  canonical?: string;
  openGraph?: { title?: string; description?: string; imageObjectKey?: string };
}

export interface Publicacion {
  id: string;
  slug: string;
  titulo: string;
  resumen: string;
  descripcion: string;
  categoria?: string;
  videoUrl?: string | null;
  enlacesX?: string[];
  estado: PublicacionEstado;
  fechaPublicacion?: string | null;
  fechaVencimiento?: string | null;
  metadataSEO?: MetadataSeo;
}

export interface PublicacionPayload extends Omit<Publicacion, 'id'> {}
