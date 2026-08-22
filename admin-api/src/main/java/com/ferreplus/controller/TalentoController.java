package com.ferreplus.controller;

import com.ferreplus.client.publico.PublicApiClient;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import com.fasterxml.jackson.databind.JsonNode;
import java.util.Arrays;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.UriComponentsBuilder;

@RestController
@RequestMapping("/api/admin/talento")
public class TalentoController {
    private final PublicApiClient client;
    public TalentoController(PublicApiClient client) { this.client = client; }
    @GetMapping("/{resource}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'VER', authentication)")
    public JsonNode list(@PathVariable String resource, HttpServletRequest request) { return client.exchange(HttpMethod.GET, internalPath(resource, request), null, JsonNode.class, correlation(request)); }
    @GetMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'VER', authentication)")
    public JsonNode get(@PathVariable String resource, @PathVariable String id, HttpServletRequest request) { return client.exchange(HttpMethod.GET, internalPath(resource + "/" + id, request), null, JsonNode.class, correlation(request)); }
    @PostMapping("/{resource}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'CREAR', authentication)")
    public JsonNode create(@PathVariable String resource, @RequestBody JsonNode body, HttpServletRequest request) { return client.exchange(HttpMethod.POST, "/api/internal/" + resource, body, JsonNode.class, correlation(request)); }
    @PutMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'EDITAR', authentication)")
    public JsonNode update(@PathVariable String resource, @PathVariable String id, @RequestBody JsonNode body, HttpServletRequest request) { return client.exchange(HttpMethod.PUT, "/api/internal/" + resource + "/" + id, body, JsonNode.class, correlation(request)); }
    @PatchMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'EDITAR', authentication)")
    public JsonNode patch(@PathVariable String resource, @PathVariable String id, @RequestBody JsonNode body, HttpServletRequest request) { return client.exchange(HttpMethod.PATCH, "/api/internal/" + resource + "/" + id, body, JsonNode.class, correlation(request)); }
    @PatchMapping("/{resource}/{id}/estado") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'EDITAR', authentication)")
    public JsonNode state(@PathVariable String resource, @PathVariable String id, @RequestBody JsonNode body, HttpServletRequest request) { return client.exchange(HttpMethod.PATCH, "/api/internal/" + resource + "/" + id, body, JsonNode.class, correlation(request)); }
    @PostMapping("/{resource}/{id}/{action}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'EDITAR', authentication)")
    public Object action(@PathVariable String resource, @PathVariable String id, @PathVariable String action, HttpServletRequest request) {
        if (!java.util.Set.of("publicar", "despublicar", "cerrar").contains(action)) {
            throw new com.ferreplus.exception.BadRequestException("Accion de talento no permitida");
        }
        return client.exchange(HttpMethod.POST, "/api/internal/" + resource + "/" + id + "/" + action, null, JsonNode.class, correlation(request));
    }
    @GetMapping("/{resource}/{id}/cv") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'VER', authentication)")
    public ResponseEntity<byte[]> cv(@PathVariable String resource, @PathVariable String id, HttpServletRequest request) {
        byte[] bytes = client.exchange(HttpMethod.GET, internalPath(resource + "/" + id + "/cv", request), null, byte[].class, correlation(request));
        return ResponseEntity.ok().body(bytes);
    }
    @DeleteMapping("/{resource}/{id}") @PreAuthorize("@talentoAuthorization.allowed(#resource, 'ELIMINAR', authentication)")
    public ResponseEntity<Void> delete(@PathVariable String resource, @PathVariable String id, HttpServletRequest request) { client.exchange(HttpMethod.DELETE, "/api/internal/" + resource + "/" + id, null, JsonNode.class, correlation(request)); return ResponseEntity.noContent().build(); }
    private String correlation(HttpServletRequest request) { return request.getHeader("X-Correlation-ID"); }
    private String internalPath(String resource, HttpServletRequest request) {
        var builder = UriComponentsBuilder.fromPath("/api/internal/" + resource);
        request.getParameterMap().forEach((name, values) -> Arrays.stream(values).forEach(value -> builder.queryParam(name, value)));
        return builder.build().encode().toUriString();
    }
}
