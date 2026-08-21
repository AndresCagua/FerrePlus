package com.ferreplus.controller;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

@Component("talentoAuthorization")
public class TalentoAuthorization {
    public boolean allowed(String resource, String action, Authentication authentication) {
        if (authentication == null) return false;
        String module = switch (resource.toLowerCase()) {
            case "publicaciones" -> "TALENTO_PUBLICACIONES";
            case "convocatorias" -> "TALENTO_CONVOCATORIAS";
            case "postulaciones" -> "TALENTO_POSTULACIONES";
            case "destinatarios" -> "TALENTO_DESTINATARIOS";
            case "contactos" -> "CONTABILIDAD_CONTACTOS";
            default -> "";
        };
        return authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals(module + "_" + action));
    }
}
