package com.ferreplus.publico.model;

import java.time.Instant;

public record CvMetadata(String objectKey, String fileName, String mimeType, long size, Instant createdAt) {}
