package com.ferreplus.controller;

import com.ferreplus.client.publico.PublicApiClient;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/talento")
public class TalentoController {
    private final PublicApiClient client;
    public TalentoController(PublicApiClient client) { this.client = client; }
    @GetMapping("/{resource}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'VER', authentication)")
    public Object list(@PathVariable String resource, HttpServletRequest request) { return client.exchange(HttpMethod.GET, "/api/internal/" + resource, null, Object.class, correlation(request)); }
    @GetMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'VER', authentication)")
    public Object get(@PathVariable String resource, @PathVariable String id, HttpServletRequest request) { return client.exchange(HttpMethod.GET, "/api/internal/" + resource + "/" + id, null, Object.class, correlation(request)); }
    @PostMapping("/{resource}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'CREAR', authentication)")
    public Object create(@PathVariable String resource, @RequestBody Object body, HttpServletRequest request) { return client.exchange(HttpMethod.POST, "/api/internal/" + resource, body, Object.class, correlation(request)); }
    @PutMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'EDITAR', authentication)")
    public Object update(@PathVariable String resource, @PathVariable String id, @RequestBody Object body, HttpServletRequest request) { return client.exchange(HttpMethod.PUT, "/api/internal/" + resource + "/" + id, body, Object.class, correlation(request)); }
    @PatchMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'EDITAR', authentication)")
    public Object patch(@PathVariable String resource, @PathVariable String id, @RequestBody Object body, HttpServletRequest request) { return client.exchange(HttpMethod.PATCH, "/api/internal/" + resource + "/" + id, body, Object.class, correlation(request)); }
    @DeleteMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'ELIMINAR', authentication)")
    public ResponseEntity<Void> delete(@PathVariable String resource, @PathVariable String id, HttpServletRequest request) { client.exchange(HttpMethod.DELETE, "/api/internal/" + resource + "/" + id, null, Object.class, correlation(request)); return ResponseEntity.noContent().build(); }
    private String correlation(HttpServletRequest request) { return request.getHeader("X-Correlation-ID"); }
}
