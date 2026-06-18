package com.iuims.registrar.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Fail fast when obvious demo-only settings are active under the production profile.
 */
@Component
@Profile("prod")
public class ProductionStartupValidator implements ApplicationRunner {

    @Value("${spring.datasource.password:}")
    private String dbPassword;

    @Value("${registrar.demo.reset-passwords-on-boot:false}")
    private boolean resetPasswordsOnBoot;

    @Value("${spring.ai.mcp.server.webmvc.enabled:true}")
    private boolean mcpEnabled;

    @Override
    public void run(ApplicationArguments args) {
        if (dbPassword == null || dbPassword.isBlank()) {
            throw new IllegalStateException(
                "Production profile requires a non-empty spring.datasource.password (use env SPRING_DATASOURCE_PASSWORD).");
        }
        if (resetPasswordsOnBoot) {
            throw new IllegalStateException(
                "registrar.demo.reset-passwords-on-boot must be false in production.");
        }
        if (mcpEnabled) {
            throw new IllegalStateException(
                "Disable MCP in production (spring.ai.mcp.server.webmvc.enabled=false).");
        }
    }
}
