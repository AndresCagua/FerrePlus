package com.ferreplus.publico.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RateLimitFilterTest {
    @Test
    void excesoDevuelve429YRetryAfter() throws Exception {
        RateLimitService service = mock(RateLimitService.class);
        when(service.allow("application", "192.0.2.10:none"))
                .thenReturn(new RateLimitService.Decision(false, 417, false));
        FilterChain chain = mock(FilterChain.class);
        RateLimitFilter filter = new RateLimitFilter(service, new ObjectMapper());
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/public/convocatorias/c-1/postulaciones");
        request.setServletPath("/api/public/convocatorias/c-1/postulaciones");
        request.setRemoteAddr("192.0.2.10");
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, chain);
        assertThat(response.getStatus()).isEqualTo(429);
        assertThat(response.getHeader("Retry-After")).isEqualTo("417");
        verifyNoInteractions(chain);
    }

    @Test
    void internalNuncaPasaPorRateLimit() throws Exception {
        RateLimitService service = mock(RateLimitService.class);
        FilterChain chain = mock(FilterChain.class);
        RateLimitFilter filter = new RateLimitFilter(service, new ObjectMapper());
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/internal/contactos");
        request.setServletPath("/api/internal/contactos");
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, chain);
        verify(chain).doFilter(request, response);
        verifyNoInteractions(service);
    }
}
