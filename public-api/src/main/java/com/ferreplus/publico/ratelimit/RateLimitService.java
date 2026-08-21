package com.ferreplus.publico.ratelimit;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Service;

@Service
public class RateLimitService {
    private static final String SCRIPT = "local n=redis.call('INCR',KEYS[1]); if n==1 then redis.call('EXPIRE',KEYS[1],ARGV[1]) end; return n";
    private final StringRedisTemplate redis;
    private final Map<String, Window> fallback = new ConcurrentHashMap<>();
    public RateLimitService(StringRedisTemplate redis) { this.redis = redis; }

    public Decision allow(String operation, String identity) {
        Limit shortLimit = operation.equals("application") ? new Limit(3, 900) : new Limit(5, 900);
        Limit dailyLimit = operation.equals("application") ? new Limit(10, 86400) : new Limit(20, 86400);
        try {
            Decision first = increment(operation + ":" + identity + ":15m", shortLimit);
            if (!first.allowed()) return first;
            Decision second = increment(operation + ":" + identity + ":day", dailyLimit);
            if (!second.allowed()) return second;
            return new Decision(true, Math.min(first.retryAfter(), second.retryAfter()), false);
        } catch (RuntimeException ignored) {
            Window current = fallback.computeIfAbsent(operation + ":" + identity, key -> new Window());
            long now = System.currentTimeMillis();
            if (now - current.startedAt > 60_000) { current.startedAt = now; current.count = 0; }
            current.count++;
            return new Decision(current.count <= 1, 60, true);
        }
    }

    private Decision increment(String key, Limit limit) {
        Long count = redis.execute(new DefaultRedisScript<>(SCRIPT, Long.class), java.util.List.of("rate:" + key),
                String.valueOf(limit.seconds()));
        long ttl = redis.getExpire("rate:" + key, java.util.concurrent.TimeUnit.SECONDS);
        return new Decision(count == null || count <= limit.max(), Math.max(1, ttl), false);
    }
    public record Decision(boolean allowed, long retryAfter, boolean degraded) {}
    private record Limit(long max, long seconds) {}
    private static final class Window { long startedAt = System.currentTimeMillis(); int count; }
}
