// Package http wires the HTTP layer: router, middleware, handlers.
//
// Handlers belong in subpackage `handlers/`. This file is responsible only
// for composition.
package http

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"

	"github.com/example/scaffolding/apps/api/internal/http/handlers"
	"github.com/example/scaffolding/apps/api/internal/http/middleware"
)

// RouterDeps groups dependencies needed to wire the router.
//
// Add fields here as the application grows (DB pool, services, etc.).
type RouterDeps struct {
	Logger  *slog.Logger
	Version string
}

// NewRouter returns a fully configured chi router.
func NewRouter(deps RouterDeps) http.Handler {
	r := chi.NewRouter()

	// --- Cross-cutting middleware (order matters) ---
	r.Use(chimw.RequestID)
	r.Use(chimw.RealIP)
	r.Use(middleware.Recovery(deps.Logger))
	r.Use(middleware.StructuredLogger(deps.Logger))
	r.Use(chimw.Timeout(15 * time.Second))
	r.Use(middleware.SecurityHeaders)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// --- Health check (always first; bypasses heavier middleware in future) ---
	startedAt := time.Now()
	healthHandler := handlers.NewHealthHandler(handlers.HealthDeps{
		Version:   deps.Version,
		StartedAt: startedAt,
		// CheckDB: <inject when DB is wired> — for now we report true unconditionally
		CheckDB: func() bool { return true },
	})
	r.Get("/healthz", healthHandler.Get)

	// --- Versioned API routes ---
	r.Route("/api/v1", func(r chi.Router) {
		// Mount feature handlers here as they are built.
		// r.Mount("/users", usersHandler.Routes())
	})

	return r
}
