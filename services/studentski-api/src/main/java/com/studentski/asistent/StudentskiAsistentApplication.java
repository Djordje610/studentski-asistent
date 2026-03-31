package com.studentski.asistent;

import com.studentski.asistent.config.JwtProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(JwtProperties.class)
public class StudentskiAsistentApplication {

    public static void main(String[] args) {
        SpringApplication.run(StudentskiAsistentApplication.class, args);
    }
}
