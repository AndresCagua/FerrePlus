package com.ferreplus.publico.config;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Slf4j
@Configuration
@EnableConfigurationProperties(MinioProperties.class)
public class MinioConfig {
    @Bean
    MinioClient minioClient(MinioProperties properties) {
        MinioClient client = MinioClient.builder().endpoint(properties.endpoint())
                .credentials(properties.accessKey(), properties.secretKey()).build();
        initializeBuckets(client, List.of(properties.cvBucket(), properties.mediaBucket()));
        return client;
    }

    private void initializeBuckets(MinioClient client, List<String> buckets) {
        for (String bucket : buckets) {
            try {
                if (!client.bucketExists(BucketExistsArgs.builder().bucket(bucket).build())) {
                    client.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
                }
            } catch (Exception exception) {
                // La API puede iniciar mientras MinIO termina su readiness; el siguiente deploy
                // o una comprobacion operativa volvera a crear los buckets idempotentemente.
                log.warn("No se pudo inicializar bucket privado {}: {}", bucket, exception.getMessage());
            }
        }
    }
}
