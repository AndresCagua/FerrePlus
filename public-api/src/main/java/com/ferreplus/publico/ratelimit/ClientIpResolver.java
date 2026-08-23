package com.ferreplus.publico.ratelimit;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Arrays;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;

/** Obtiene la IP del cliente solo cuando la conexion inmediata proviene de un proxy confiable. */
@Component
public class ClientIpResolver {
    private final String forwardedHeader;

    public ClientIpResolver(@Value("${app.rate-limit.trusted-proxy-header:X-Forwarded-For}") String forwardedHeader) {
        this.forwardedHeader = forwardedHeader;
    }

    public String resolve(HttpServletRequest request) {
        String remoteAddress = request.getRemoteAddr();
        if (!isPrivateProxy(remoteAddress)) {
            return remoteAddress;
        }
        String forwarded = request.getHeader(forwardedHeader);
        if (forwarded == null || forwarded.isBlank()) {
            forwarded = request.getHeader("X-Real-IP");
        }
        if (forwarded == null || forwarded.isBlank()) {
            return remoteAddress;
        }
        return Arrays.stream(forwarded.split(","))
                .map(String::trim)
                .filter(this::isIpLiteral)
                .findFirst()
                .orElse(remoteAddress);
    }

    private boolean isPrivateProxy(String address) {
        return address != null && (address.equals("127.0.0.1") || address.equals("::1")
                || address.startsWith("10.") || address.startsWith("192.168.")
                || isPrivate172(address));
    }

    private boolean isPrivate172(String address) {
        if (!address.startsWith("172.")) {
            return false;
        }
        String[] parts = address.split("\\.");
        if (parts.length < 2) {
            return false;
        }
        try {
            int secondOctet = Integer.parseInt(parts[1]);
            return secondOctet >= 16 && secondOctet <= 31;
        } catch (NumberFormatException ignored) {
            return false;
        }
    }

    private boolean isIpLiteral(String value) {
        return value.matches("(?:\\d{1,3}\\.){3}\\d{1,3}")
                || value.matches("[0-9a-fA-F:]+") && value.contains(":");
    }
}
