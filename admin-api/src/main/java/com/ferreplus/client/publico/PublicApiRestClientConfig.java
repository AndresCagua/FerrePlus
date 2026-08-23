package com.ferreplus.client.publico;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
@Configuration
public class PublicApiRestClientConfig { @Bean RestClient.Builder restClientBuilder() { return RestClient.builder(); } }
