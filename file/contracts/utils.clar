;; Utilities module (placeholder)
(define-read-only (percent-of (amount uint) (percent uint))
  (/ (* amount percent) u100)
)
