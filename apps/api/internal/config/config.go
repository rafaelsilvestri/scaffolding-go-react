// Package config carrega e valida configuração da aplicação a partir de
// variáveis de ambiente. NUNCA leia env vars fora deste pacote.
package config

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

// Config holds all runtime configuration for the API.
type Config struct {
	HTTPAddr      string
	DatabaseURL   string
	AllowedOrigin string
	Environment   string // "development" | "staging" | "production"
}

// Load reads env vars and returns a validated Config.
//
// Errors describe the missing/invalid var without leaking secret values.
func Load() (*Config, error) {
	cfg := &Config{
		HTTPAddr:      getEnv("HTTP_ADDR", ":8080"),
		DatabaseURL:   os.Getenv("DATABASE_URL"),
		AllowedOrigin: getEnv("ALLOWED_ORIGIN", "http://localhost:5173"),
		Environment:   getEnv("ENVIRONMENT", "development"),
	}

	var errs []string

	if !strings.HasPrefix(cfg.HTTPAddr, ":") && !strings.Contains(cfg.HTTPAddr, ":") {
		errs = append(errs, "HTTP_ADDR must be host:port or :port")
	}

	switch cfg.Environment {
	case "development", "staging", "production":
	default:
		errs = append(errs, fmt.Sprintf("ENVIRONMENT must be development|staging|production (got %q)", cfg.Environment))
	}

	// In non-development environments, DATABASE_URL must be set.
	if cfg.Environment != "development" && cfg.DatabaseURL == "" {
		errs = append(errs, "DATABASE_URL is required outside development")
	}

	if len(errs) > 0 {
		return nil, errors.New("invalid config: " + strings.Join(errs, "; "))
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}
