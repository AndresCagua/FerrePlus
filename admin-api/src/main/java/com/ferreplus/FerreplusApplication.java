package com.ferreplus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class FerreplusApplication {

    public static void main(String[] args) {
        SpringApplication.run(FerreplusApplication.class, args);
    }
}
