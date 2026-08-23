const DATETIME_LOCAL_PATTERN = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/;

export function datetimeLocalToInstant(value: string | null): string {
  const match = value?.match(DATETIME_LOCAL_PATTERN);
  if (!match) throw new Error('La fecha debe tener un formato valido');

  const [, year, month, day, hours, minutes] = match;
  const date = new Date(Number(year), Number(month) - 1, Number(day), Number(hours), Number(minutes));
  if (date.getFullYear() !== Number(year) || date.getMonth() !== Number(month) - 1
      || date.getDate() !== Number(day) || date.getHours() !== Number(hours)
      || date.getMinutes() !== Number(minutes)) {
    throw new Error('La fecha indicada no es valida');
  }
  return date.toISOString();
}

export function instantToDatetimeLocal(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new Error('La fecha recibida no es valida');
  const pad = (part: number) => String(part).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}
