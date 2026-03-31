package com.studentski.auth.config;

import com.studentski.auth.entity.User;
import com.studentski.auth.entity.UserRole;
import com.studentski.auth.repository.UserRepository;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class AdminBootstrap {

    @Bean
    ApplicationRunner seedAdmin(UserRepository users, PasswordEncoder encoder) {
        return args -> {
            String email = "admin@admin.local";
            users.findByEmailIgnoreCase(email).ifPresentOrElse(
                    u -> {
                        if (u.getRole() != UserRole.ADMIN) {
                            u.setRole(UserRole.ADMIN);
                            users.save(u);
                        }
                    },
                    () -> {
                        User u = new User();
                        u.setEmail(email);
                        u.setPasswordHash(encoder.encode("Admin123!"));
                        u.setFullName("Administrator");
                        u.setStudentIndex(null);
                        u.setRole(UserRole.ADMIN);
                        users.save(u);
                    }
            );
        };
    }
}
