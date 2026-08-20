export interface MediaImage {
  objectKey?: string;
  alt?: string;
  url?: string;
}

export interface SeoMetadata {
  title?: string;
  description?: string;
  canonical?: string;
  openGraph?: { title?: string; description?: string; imageObjectKey?: string };
}

export interface Publicacion {
  id: string;
  slug: string;
  titulo: string;
  resumen?: string;
  descripcion?: string;
  portada?: MediaImage;
  galeria?: MediaImage[];
  videoUrl?: string;
  enlacesX?: string[];
  categoria?: string;
  fechaPublicacion?: string;
  metadataSEO?: SeoMetadata;
}

export interface Convocatoria {
  id: string;
  titulo: string;
  descripcion: string;
  requisitos?: string[];
  ubicacion?: string;
  modalidad?: string;
  fechaApertura?: string;
  fechaCierre?: string;
}

export interface ApplicationData {
  nombres: string;
  apellidos: string;
  email: string;
  telefono: string;
  ciudad: string;
  honeypot?: string;
}

export interface ContactData {
  nombre: string;
  email: string;
  telefono?: string;
  asunto: string;
  mensaje: string;
  honeypot?: string;
}

export interface ApiErrorShape {
  status: number;
  message: string;
  fields?: Record<string, string>;
}

export class PublicApiError extends Error {
  constructor(public readonly status: number, message: string, public readonly fields?: Record<string, string>) {
    super(message);
    this.name = 'PublicApiError';
  }
}
