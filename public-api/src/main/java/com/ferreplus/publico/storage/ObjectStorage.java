package com.ferreplus.publico.storage;

import java.io.InputStream;

public interface ObjectStorage {
    String put(String bucket, String objectKey, InputStream content, long size, String mimeType);
    StoredObject get(String bucket, String objectKey);
    void delete(String bucket, String objectKey);

    record StoredObject(InputStream stream, long size, String contentType) {}
}
