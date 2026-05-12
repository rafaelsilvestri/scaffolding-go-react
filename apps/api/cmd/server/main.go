// Package main is the entry point of the API server.
//
// It wires configuration, dependencies, and the HTTP router, then blocks on
// the server until a SIGINT/SIGTERM is received and shuts down gracefully.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/example/scaffolding/apps/api/internal/config"
	apphttp "github.com/example/scaffolding/apps/api/internal/http"
)

// Build-time variables (set via -ldflags). Default to "dev" so local builds
// remain functional even without ldflags.
var (
	version = "dev"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	cfg, err := config.Load()
	if err != nil {
		logger.Error("config load failed", slog.Any("err", err))
		os.Exit(1)
	}

	router := apphttp.NewRouter(apphttp.RouterDeps{
		Logger:  logger,
		Version: version,
	})

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	// Start server.
	go func() {
		logger.Info("server listening", slog.String("addr", cfg.HTTPAddr), slog.String("version", version))
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("server failed", slog.Any("err", err))
			os.Exit(1)
		}
	}()

	// Graceful shutdown.
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	logger.Info("shutdown initiated")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Error("graceful shutdown failed", slog.Any("err", err))
		os.Exit(1)
	}
	logger.Info("shutdown complete")
}
