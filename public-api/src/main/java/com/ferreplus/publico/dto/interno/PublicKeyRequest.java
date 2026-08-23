package com.ferreplus.publico.dto.interno;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record PublicKeyRequest(@NotBlank String kid, @NotBlank String publicKey, @NotNull Instant expiration) {}
