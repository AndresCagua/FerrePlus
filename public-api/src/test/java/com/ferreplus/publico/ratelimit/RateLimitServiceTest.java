package com.ferreplus.publico.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;

class RateLimitServiceTest {
    @Test
    void applicationUsesThreePerWindowAndTenPerDay() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        Map<String, Long> counts = new ConcurrentHashMap<>();
        when(redis.execute(any(DefaultRedisScript.class), anyList(), anyString())).thenAnswer(invocation -> {
            String key = ((java.util.List<String>) invocation.getArgument(1)).get(0);
            return counts.merge(key, 1L, Long::sum);
        });
        when(redis.getExpire(anyString(), any())).thenReturn(900L);
        RateLimitService service = new RateLimitService(redis);
        assertThat(service.allow("application", "ip-a").allowed()).isTrue();
        assertThat(service.allow("application", "ip-a").allowed()).isTrue();
        assertThat(service.allow("application", "ip-a").allowed()).isTrue();
        RateLimitService.Decision rejected = service.allow("application", "ip-a");
        assertThat(rejected.allowed()).isFalse();
        assertThat(rejected.retryAfter()).isPositive();
    }

    @Test
    void redisFailureUsesBoundedFallback() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        when(redis.execute(any(DefaultRedisScript.class), anyList(), anyString())).thenThrow(new RuntimeException("redis down"));
        RateLimitService service = new RateLimitService(redis);
        assertThat(service.allow("contact", "ip-a").allowed()).isTrue();
        RateLimitService.Decision rejected = service.allow("contact", "ip-a");
        assertThat(rejected.allowed()).isFalse();
        assertThat(rejected.degraded()).isTrue();
    }
}
