export type ContactoEstado = 'UNREAD' | 'READ';

export interface Contacto {
  id: string;
  nombre: string;
  email: string;
  telefono?: string;
  asunto: string;
  mensaje: string;
  estado: ContactoEstado;
  createdAt: string;
}
