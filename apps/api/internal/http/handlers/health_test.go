package handlers_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"github.com/example/scaffolding/apps/api/internal/http/handlers"
)

// healthBody mirrors handlers.healthResponse but lives in the test package
// so we don't depend on unexported types.
type healthBody struct {
	Status        string `json:"status"`
	Version       string `json:"version"`
	UptimeSeconds int64  `json:"uptime_seconds"`
	Checks        struct {
		Database bool `json:"database"`
	} `json:"checks"`
}

func newRecorder() *httptest.ResponseRecorder { return httptest.NewRecorder() }

// AC1, AC2, AC4: ok status, version, uptime when DB is healthy.
func TestHealth_OkWhenDatabaseUp(t *testing.T) {
	h := handlers.NewHealthHandler(handlers.HealthDeps{
		Version:   "1.2.3",
		StartedAt: time.Now().Add(-30 * time.Second),
		CheckDB:   func() bool { return true },
	})

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := newRecorder()
	h.Get(rr, req)

	require.Equal(t, http.StatusOK, rr.Code)
	var got healthBody
	require.NoError(t, json.Unmarshal(rr.Body.Bytes(), &got))
	require.Equal(t, "ok", got.Status)
	require.Equal(t, "1.2.3", got.Version)
	require.True(t, got.Checks.Database)
	require.GreaterOrEqual(t, got.UptimeSeconds, int64(29))
}

// AC3: degraded when DB unreachable, but still 200.
func TestHealth_DegradedWhenDatabaseDown(t *testing.T) {
	h := handlers.NewHealthHandler(handlers.HealthDeps{
		Version:   "dev",
		StartedAt: time.Now(),
		CheckDB:   func() bool { return false },
	})

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := newRecorder()
	h.Get(rr, req)

	require.Equal(t, http.StatusOK, rr.Code, "AC3: degraded must still be 200")
	var got healthBody
	require.NoError(t, json.Unmarshal(rr.Body.Bytes(), &got))
	require.Equal(t, "degraded", got.Status)
	require.False(t, got.Checks.Database)
}

// Sanity: response is JSON.
func TestHealth_ContentTypeIsJSON(t *testing.T) {
	h := handlers.NewHealthHandler(handlers.HealthDeps{
		Version:   "dev",
		StartedAt: time.Now(),
	})
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := newRecorder()
	h.Get(rr, req)
	require.Contains(t, rr.Header().Get("Content-Type"), "application/json")
}
