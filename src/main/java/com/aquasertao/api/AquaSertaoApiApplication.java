package com.aquasertao.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.io.File;
import java.nio.file.Files;
import java.util.List;

@SpringBootApplication
public class AquaSertaoApiApplication {

	public static void main(String[] args) {
		loadDotEnv();
		SpringApplication.run(AquaSertaoApiApplication.class, args);
	}

	private static void loadDotEnv() {
		try {
			File envFile = new File(".env");
			if (envFile.exists()) {
				List<String> lines = Files.readAllLines(envFile.toPath());
				for (String line : lines) {
					line = line.trim();
					if (line.isEmpty() || line.startsWith("#")) continue;
					int eqIdx = line.indexOf('=');
					if (eqIdx > 0) {
						String key = line.substring(0, eqIdx).trim();
						String value = line.substring(eqIdx + 1).trim();
						if (System.getProperty(key) == null) {
							System.setProperty(key, value);
						}
					}
				}
			}
		} catch (Exception e) {
			System.err.println("Aviso: Não foi possível carregar arquivo .env: " + e.getMessage());
		}
	}

}
