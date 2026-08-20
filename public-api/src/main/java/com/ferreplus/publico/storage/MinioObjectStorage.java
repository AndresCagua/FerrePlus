package com.ferreplus.publico.storage;

import com.ferreplus.publico.config.MinioProperties;
import io.minio.GetObjectArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import io.minio.StatObjectArgs;
import java.io.InputStream;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MinioObjectStorage implements ObjectStorage {
    private final MinioClient client;
    private final MinioProperties properties;

    @Override
    public String put(String bucket, String objectKey, InputStream content, long size, String mimeType) {
        try {
            client.putObject(PutObjectArgs.builder().bucket(bucket).object(objectKey).stream(content, size, -1)
                    .contentType(mimeType).headers(Map.of("X-Amz-Meta-Private", "true")).build());
            return objectKey;
        } catch (Exception exception) {
            throw new StorageException("No fue posible almacenar el CV", exception);
        }
    }

    @Override
    public StoredObject get(String bucket, String objectKey) {
        try {
            var stat = client.statObject(StatObjectArgs.builder().bucket(bucket).object(objectKey).build());
            var response = client.getObject(GetObjectArgs.builder().bucket(bucket).object(objectKey).build());
            return new StoredObject(response, stat.size(), stat.contentType());
        } catch (Exception exception) {
            throw new StorageException("El archivo CV no existe", exception);
        }
    }

    @Override
    public void delete(String bucket, String objectKey) {
        try {
            client.removeObject(RemoveObjectArgs.builder().bucket(bucket).object(objectKey).build());
        } catch (Exception exception) {
            throw new StorageException("No fue posible limpiar el objeto CV", exception);
        }
    }

    public String cvBucket() { return properties.cvBucket(); }
    public String mediaBucket() { return properties.mediaBucket(); }

    public static class StorageException extends RuntimeException {
        public StorageException(String message, Throwable cause) { super(message, cause); }
    }
}
