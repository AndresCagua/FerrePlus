-- Módulo de Logs — índices para filtrado y borrado por rango sobre auditoría.
--
-- IMPORTANTE:
--  * NO los crea `ddl-auto` (hibernate), por lo que se aplican MANUALMENTE
--    tras revisión del operador (regla de BD del proyecto: el agente no ejecuta DDL).
--  * Aplicar con: psql -U <user> -d <db> -f indices-auditoria.sql
--  * El borrado masivo DELETE ... WHERE fecha BETWEEN ... y los filtros por
--    fecha/entidad del módulo de logs se benefician de estos índices.

CREATE INDEX IF NOT EXISTS idx_auditoria_fecha ON auditoria (fecha);
CREATE INDEX IF NOT EXISTS idx_auditoria_entidad_fecha ON auditoria (entidad, fecha);
