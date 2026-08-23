package com.ferreplus.publico.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

class RateLimitFilterTest {
    @Test
    void excesoDevuelve429YRetryAfter() throws Exception {
        RateLimitService service = mock(RateLimitService.class);
        when(service.allow(eq("application"), eq("192.0.2.10"), isNull(), isNull()))
                .thenReturn(new RateLimitService.Decision(false, 417, false));
        FilterChain chain = mock(FilterChain.class);
        RateLimitFilter filter = new RateLimitFilter(service, new ObjectMapper(), new ClientIpResolver("X-Forwarded-For"), "test-secret");
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/public/convocatorias/c-1/postulaciones");
        request.setServletPath("/api/public/convocatorias/c-1/postulaciones");
        request.setRemoteAddr("192.0.2.10");
        request.setContentType("application/json");
        request.setContent("{}".getBytes());
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
        RateLimitFilter filter = new RateLimitFilter(service, new ObjectMapper(), new ClientIpResolver("X-Forwarded-For"), "test-secret");
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/internal/contactos");
        request.setServletPath("/api/internal/contactos");
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, chain);
        verify(chain).doFilter(request, response);
        verifyNoInteractions(service);
    }

    @Test
    void combinaIpProxyConEmailNormalizado() throws Exception {
        RateLimitService service = mock(RateLimitService.class);
        when(service.allow(anyString(), anyString(), any(), any()))
                .thenReturn(new RateLimitService.Decision(true, 900, false));
        FilterChain chain = mock(FilterChain.class);
        RateLimitFilter filter = new RateLimitFilter(service, new ObjectMapper(),
                new ClientIpResolver("X-Forwarded-For"), "test-secret");
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/public/contactos");
        request.setServletPath("/api/public/contactos");
        request.setRemoteAddr("10.0.0.4");
        request.addHeader("X-Forwarded-For", "198.51.100.20, 10.0.0.4");
        request.setContentType("application/json");
        request.setContent("{\"email\":\" User@Example.COM \"}".getBytes());

        filter.doFilter(request, new MockHttpServletResponse(), chain);

        verify(service).allow(eq("contact"), eq("198.51.100.20"), isNull(), argThat(value -> value != null));
        verify(chain).doFilter(any(), any());
    }

    @Test
    void multipartGrandeNoSeLeeNiSeAlmacenaEnElFiltro() throws Exception {
        RateLimitService service = mock(RateLimitService.class);
        when(service.allow(anyString(), anyString(), isNull(), isNull()))
                .thenReturn(new RateLimitService.Decision(true, 900, false));
        FilterChain chain = mock(FilterChain.class);
        RateLimitFilter filter = new RateLimitFilter(service, new ObjectMapper(),
                new ClientIpResolver("X-Forwarded-For"), "test-secret");
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/public/convocatorias/c-1/postulaciones");
        request.setServletPath("/api/public/convocatorias/c-1/postulaciones");
        request.setRemoteAddr("192.0.2.20");
        request.setContentType("multipart/form-data; boundary=test");
        request.setContent(new byte[1024 * 1024]);

        filter.doFilter(request, new MockHttpServletResponse(), chain);

        verify(chain).doFilter(same(request), any());
        verify(service).allow("application", "192.0.2.20", null, null);
    }

    @Test
    void multipartConcurrenteMantieneElFlujoSinLeerElCuerpo() throws Exception {
        RateLimitService service = mock(RateLimitService.class);
        when(service.allow(anyString(), anyString(), isNull(), isNull()))
                .thenReturn(new RateLimitService.Decision(true, 900, false));
        RateLimitFilter filter = new RateLimitFilter(service, new ObjectMapper(),
                new ClientIpResolver("X-Forwarded-For"), "test-secret");
        ExecutorService executor = Executors.newFixedThreadPool(8);
        for (int i = 0; i < 32; i++) {
            executor.submit(() -> {
                try {
                    MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/public/contactos");
                    request.setServletPath("/api/public/contactos");
                    request.setRemoteAddr("192.0.2.21");
                    request.setContentType("multipart/form-data; boundary=test");
                    request.setContent(new byte[512 * 1024]);
                    filter.doFilter(request, new MockHttpServletResponse(), mock(FilterChain.class));
                } catch (Exception exception) {
                    throw new AssertionError(exception);
                }
            });
        }
        executor.shutdown();
        assertThat(executor.awaitTermination(5, TimeUnit.SECONDS)).isTrue();
        verify(service, times(32)).allow("contact", "192.0.2.21", null, null);
    }
}
