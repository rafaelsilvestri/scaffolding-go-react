// Package domain holds entities and business rules that have no I/O.
//
// Sentinel errors here are the canonical contract that other layers rely on
// to discriminate failure modes. See ADR-0003.
package domain

import "errors"

var (
	// ErrNotFound is returned when a resource lookup yields no result.
	ErrNotFound = errors.New("domain: not found")

	// ErrConflict is returned when a write violates uniqueness or invariants.
	ErrConflict = errors.New("domain: conflict")

	// ErrInvalidInput is returned for domain-level invalid data (after HTTP-layer validation passed).
	ErrInvalidInput = errors.New("domain: invalid input")

	// ErrUnauthorized is returned when authentication is missing or invalid.
	ErrUnauthorized = errors.New("domain: unauthorized")

	// ErrForbidden is returned when the caller is authenticated but lacks permission.
	ErrForbidden = errors.New("domain: forbidden")
)
