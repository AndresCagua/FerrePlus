package com.ferreplus.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI ferreplusOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("FerrePlus API")
                        .description("API REST para sistema de gestión de inventario y ventas de ferretería")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("FerrePlus")
                                .email("admin@ferreplus.com")))
                .addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
                .components(new Components()
                        .addSecuritySchemes("Bearer Authentication",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("Ingresa el token JWT sin el prefijo 'Bearer'. Obtenlo desde POST /api/auth/login")));
    }
}
