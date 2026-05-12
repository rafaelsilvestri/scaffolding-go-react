// Package response standardizes HTTP responses across the API.
//
// See ADR-0003 for design notes:
//   - Success: payload returned directly (no envelope).
//   - Error:   typed `Error` schema (matches OpenAPI components/schemas/Error).
package response

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	chimw "github.com/go-chi/chi/v5/middleware"

	"github.com/example/scaffolding/apps/api/internal/domain"
)

// AppError is the wire format of an error. It MUST stay in sync with the
// `Error` schema in docs/api/openapi.yaml.
type AppError struct {
	Code      string         `json:"code"`
	Message   string         `json:"message"`
	Details   map[string]any `json:"details,omitempty"`
	RequestID string         `json:"request_id,omitempty"`

	// httpStatus is not serialized; used internally to write the right code.
	httpStatus int
}

// Common predefined errors. New ones go here, not at call sites.
var (
	ErrInvalidJSON = &AppError{Code: "INVALID_JSON", Message: "request body is not valid JSON", httpStatus: http.StatusBadRequest}
	ErrInternal    = &AppError{Code: "INTERNAL", Message: "internal server error", httpStatus: http.StatusInternalServerError}
)

// ErrValidation builds a 400 with field-level details.
func ErrValidation(details map[string]any) *AppError {
	return &AppError{
		Code:       "VALIDATION_FAILED",
		Message:    "one or more fields failed validation",
		Details:    details,
		httpStatus: http.StatusBadRequest,
	}
}

// OK writes a JSON response with the given status and payload.
//
// `data` may be nil for 204; otherwise it is JSON-encoded.
func OK(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	if data == nil || status == http.StatusNoContent {
		w.WriteHeader(status)
		return
	}
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(data); err != nil {
		slog.Error("response encode failed", slog.Any("err", err))
	}
}

// Error writes an AppError as JSON with the right status.
func Error(w http.ResponseWriter, r *http.Request, err *AppError) {
	if err == nil {
		err = ErrInternal
	}
	if err.RequestID == "" {
		err.RequestID = chimw.GetReqID(r.Context())
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(err.httpStatus)
	if encErr := json.NewEncoder(w).Encode(err); encErr != nil {
		slog.Error("error encode failed", slog.Any("err", encErr))
	}
}

// MapServiceError translates domain sentinel errors to AppError + HTTP code.
//
// Unknown errors are mapped to 500 INTERNAL with no details exposed to the
// client. Full error is logged.
func MapServiceError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, domain.ErrNotFound):
		Error(w, r, &AppError{Code: "NOT_FOUND", Message: "resource not found", httpStatus: http.StatusNotFound})
	case errors.Is(err, domain.ErrConflict):
		Error(w, r, &AppError{Code: "CONFLICT", Message: "resource already exists", httpStatus: http.StatusConflict})
	case errors.Is(err, domain.ErrInvalidInput):
		Error(w, r, &AppError{Code: "VALIDATION_FAILED", Message: err.Error(), httpStatus: http.StatusBadRequest})
	case errors.Is(err, domain.ErrUnauthorized):
		Error(w, r, &AppError{Code: "UNAUTHORIZED", Message: "authentication required", httpStatus: http.StatusUnauthorized})
	case errors.Is(err, domain.ErrForbidden):
		Error(w, r, &AppError{Code: "FORBIDDEN", Message: "insufficient permissions", httpStatus: http.StatusForbidden})
	default:
		slog.Error("unmapped service error", slog.Any("err", err))
		Error(w, r, ErrInternal)
	}
}
