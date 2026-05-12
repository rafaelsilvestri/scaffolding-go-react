// Package handlers contains HTTP handlers — one file per resource.
//
// Handlers parse and validate the request, delegate to services, then write
// the response via internal/http/response.
package handlers

import (
	"net/http"
	"time"

	"github.com/example/scaffolding/apps/api/internal/http/response"
)

// HealthDeps groups the dependencies of HealthHandler.
type HealthDeps struct {
	Version   string
	StartedAt time.Time
	// CheckDB returns true if the database ping succeeds within the timeout.
	// It MUST NOT block longer than 100ms — the caller is responsible for that.
	CheckDB func() bool
}

// HealthHandler serves the /healthz endpoint.
//
// See specs/0001-health-check/spec.md for acceptance criteria.
type HealthHandler struct {
	deps HealthDeps
}

// NewHealthHandler constructs a HealthHandler.
func NewHealthHandler(deps HealthDeps) *HealthHandler {
	if deps.CheckDB == nil {
		deps.CheckDB = func() bool { return true }
	}
	return &HealthHandler{deps: deps}
}

// healthResponse mirrors HealthStatus in docs/api/openapi.yaml.
//
// JSON tags MUST match the OpenAPI schema; CI validates this in `make validate`.
type healthResponse struct {
	Status        string        `json:"status"`
	Version       string        `json:"version"`
	UptimeSeconds int64         `json:"uptime_seconds"`
	Checks        healthChecks  `json:"checks"`
}

type healthChecks struct {
	Database bool `json:"database"`
}

// Get handles GET /healthz.
//
// Returns 200 unconditionally — the `status` field discriminates ok/degraded.
// This intentionally keeps the load balancer holding the pod even when a
// downstream is unhealthy (degraded != down).
func (h *HealthHandler) Get(w http.ResponseWriter, r *http.Request) {
	dbOK := h.deps.CheckDB()
	status := "ok"
	if !dbOK {
		status = "degraded"
	}

	body := healthResponse{
		Status:        status,
		Version:       h.deps.Version,
		UptimeSeconds: int64(time.Since(h.deps.StartedAt).Seconds()),
		Checks:        healthChecks{Database: dbOK},
	}
	response.OK(w, http.StatusOK, body)
}
