package com.ferreplus.publico.controller;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal")
public class InternalController {
    /** Endpoint minimo para readiness de Traefik y Compose; las operaciones internas reales llegan en PR8. */
    @GetMapping("/ping")
    public Map<String, String> ping() {
        return Map.of("service", "public-api", "boundary", "internal", "status", "ok");
    }
}
