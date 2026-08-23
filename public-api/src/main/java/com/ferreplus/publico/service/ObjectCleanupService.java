package com.ferreplus.publico.service;

import com.ferreplus.publico.storage.ObjectStorage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class ObjectCleanupService {
    private final ObjectStorage storage;
    public void cleanup(String bucket, String key) {
        try { storage.delete(bucket, key); }
        catch (RuntimeException exception) { log.error("storage.orphan_cleanup_failed objectKey={}", key); }
    }
}
