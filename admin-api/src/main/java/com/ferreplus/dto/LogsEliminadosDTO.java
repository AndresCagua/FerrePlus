package com.ferreplus.dto;

/**
 * Respuesta de {@code DELETE /api/logs} (R3): {@code { "eliminados": N }}.
 */
public class LogsEliminadosDTO {

    private int eliminados;

    public LogsEliminadosDTO() {
    }

    public LogsEliminadosDTO(int eliminados) {
        this.eliminados = eliminados;
    }

    public int getEliminados() {
        return eliminados;
    }

    public void setEliminados(int eliminados) {
        this.eliminados = eliminados;
    }
}
