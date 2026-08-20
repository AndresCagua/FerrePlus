export type DestinatarioTipo = 'JOB_APPLICATION' | 'CONTACT_FORM';

export interface Destinatario {
  id: string;
  tipo: DestinatarioTipo;
  email: string;
  activo: boolean;
}

export type DestinatarioPayload = Omit<Destinatario, 'id'>;
