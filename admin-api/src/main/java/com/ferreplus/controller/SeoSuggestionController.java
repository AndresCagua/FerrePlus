package com.ferreplus.controller;

import com.ferreplus.dto.SeoSuggestionRequest;
import com.ferreplus.dto.SeoSuggestionResponse;
import com.ferreplus.exception.SeoSuggestionException;
import com.ferreplus.service.seo.SeoSuggestionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.stream.Collectors;
import org.slf4j.MDC;

@RestController
@RequestMapping("/api/admin/talento")
public class SeoSuggestionController {
    private final SeoSuggestionService service;

    public SeoSuggestionController(SeoSuggestionService service) {
        this.service = service;
    }

    @PostMapping("/publicaciones/seo")
    @PreAuthorize("hasAnyAuthority('TALENTO_PUBLICACIONES_CREAR', 'TALENTO_PUBLICACIONES_EDITAR')")
    public SeoSuggestionResponse suggest(@Valid @RequestBody SeoSuggestionRequest request) {
        return service.suggest(request);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail validation(MethodArgumentNotValidException exception, HttpServletRequest request) {
        String detail = exception.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return problem(HttpStatus.BAD_REQUEST, detail, request);
    }

    @ExceptionHandler(SeoSuggestionException.class)
    public ProblemDetail provider(SeoSuggestionException exception, HttpServletRequest request) {
        HttpStatus status = HttpStatus.resolve(exception.getStatusCode());
        if (status != HttpStatus.BAD_GATEWAY && status != HttpStatus.SERVICE_UNAVAILABLE) {
            status = HttpStatus.SERVICE_UNAVAILABLE;
        }
        return problem(status, status == HttpStatus.BAD_GATEWAY
                ? "La respuesta SEO esta incompleta" : "El servicio SEO no esta disponible", request);
    }

    private ProblemDetail problem(HttpStatus status, String detail, HttpServletRequest request) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, detail);
        String correlationId = MDC.get("correlationId");
        problem.setProperty("correlationId", correlationId != null ? correlationId : request.getHeader("X-Correlation-ID"));
        return problem;
    }
}
