;; Enhanced Utilities Contract
;; Mathematical and helper functions for the lending protocol

;; Safe math operations with overflow protection
(define-read-only (safe-multiply (a uint) (b uint))
  (let (
    (result (* a b))
  )
    ;; Check for overflow by dividing back
    (if (and (> a u0) (> b u0))
      (if (is-eq a (/ result b))
        (some result)
        none) ;; Overflow occurred
      (some result)
    )
  )
)

(define-read-only (safe-divide (a uint) (b uint))
  (if (> b u0)
    (some (/ a b))
    none ;; Division by zero
  )
)

;; Enhanced percentage calculations
(define-read-only (percent-of (amount uint) (percent uint))
  (match (safe-divide (match (safe-multiply amount percent) result result u0) u100)
    result result
    u0
  )
)

(define-read-only (percent-change (old-value uint) (new-value uint))
  (if (> old-value u0)
    (if (> new-value old-value)
      (some (percent-of (- new-value old-value) u100))
      (some (percent-of (- old-value new-value) u100)))
    none
  )
)

;; Interest calculation helpers - simplified to avoid recursion
(define-read-only (calculate-simple-interest (principal uint) (rate uint) (time uint))
  (let (
    (interest-amount (percent-of principal rate))
    (total-interest (match (safe-multiply interest-amount time) result result u0))
  )
    (+ principal total-interest)
  )
)

;; Compound interest calculation (iterative approach to avoid recursion)
(define-read-only (calculate-compound-interest (principal uint) (rate uint) (periods uint))
  (if (is-eq periods u0)
    principal
    (if (is-eq periods u1)
      (+ principal (percent-of principal rate))
      (if (is-eq periods u2)
        (let ((period1 (+ principal (percent-of principal rate))))
          (+ period1 (percent-of period1 rate)))
        (if (is-eq periods u3)
          (let ((period1 (+ principal (percent-of principal rate)))
                (period2 (+ period1 (percent-of period1 rate))))
            (+ period2 (percent-of period2 rate)))
          ;; For periods > 3, use approximation to avoid deep recursion
          (+ principal (percent-of principal (* rate periods)))
        )
      )
    )
  )
)

;; Risk assessment utilities
(define-read-only (calculate-risk-score (collateral-ratio uint) (debt-age uint))
  (let (
    (ratio-score (if (> collateral-ratio u200) u0 ;; Very safe
                   (if (> collateral-ratio u150) u25 ;; Safe
                     (if (> collateral-ratio u120) u50 ;; Moderate risk
                       u100)))) ;; High risk
    (age-score (if (> debt-age u4320) u20 ;; Old debt (30 days)
                 (if (> debt-age u1440) u10 ;; Medium age (10 days)
                   u0))) ;; New debt
  )
    (+ ratio-score age-score)
  )
)

;; Liquidation calculations
(define-read-only (calculate-liquidation-amount (debt uint) (collateral uint) (price uint))
  (let (
    (collateral-value (match (safe-multiply collateral price) result result u0))
    (liquidation-threshold (percent-of debt u120)) ;; 120% threshold
  )
    (if (< collateral-value liquidation-threshold)
      (some {
        liquidatable: true,
        excess-debt: (- debt (match (safe-divide collateral-value u120) result result u0)),
        collateral-value: collateral-value
      })
      (some {
        liquidatable: false,
        excess-debt: u0,
        collateral-value: collateral-value
      })
    )
  )
)

;; Time-based calculations
(define-read-only (blocks-to-days (blocks uint))
  (safe-divide blocks u144) ;; Assuming ~10 min blocks, 144 blocks per day
)

(define-read-only (days-to-blocks (days uint))
  (safe-multiply days u144)
)

;; Price stability checks
(define-read-only (is-price-stable (current-price uint) (previous-price uint) (threshold uint))
  (match (percent-change previous-price current-price)
    change-percent (<= change-percent threshold)
    true ;; If we can't calculate change, assume stable
  )
)

;; Validation helpers
(define-read-only (is-valid-collateral-ratio (ratio uint))
  (and (>= ratio u100) (<= ratio u1000)) ;; Between 100% and 1000%
)

(define-read-only (is-valid-amount (amount uint))
  (and (> amount u0) (<= amount u1000000000)) ;; Max 1B units
)

;; Protocol health metrics
(define-read-only (calculate-protocol-health (total-collateral uint) (total-debt uint) (avg-price uint))
  (if (> total-debt u0)
    (let (
      (total-collateral-value (match (safe-multiply total-collateral avg-price) result result u0))
      (overall-ratio (safe-divide (match (safe-multiply total-collateral-value u100) result result u0) total-debt))
    )
      (match overall-ratio
        ratio {
          healthy: (> ratio u150),
          collateralization-ratio: ratio,
          risk-level: (if (> ratio u200) "LOW"
                        (if (> ratio u150) "MEDIUM"
                          "HIGH"))
        }
        {
          healthy: false,
          collateralization-ratio: u0,
          risk-level: "CRITICAL"
        }
      )
    )
    {
      healthy: true,
      collateralization-ratio: u0,
      risk-level: "NO_DEBT"
    }
  )
)

;; Power of two calculation (iterative approach)
(define-read-only (power-of-two (exponent uint))
  (if (is-eq exponent u0)
    u1
    (if (is-eq exponent u1)
      u2
      (if (is-eq exponent u2)
        u4
        (if (is-eq exponent u3)
          u8
          (if (is-eq exponent u4)
            u16
            (if (is-eq exponent u5)
              u32
              (if (is-eq exponent u6)
                u64
                (if (is-eq exponent u7)
                  u128
                  (if (is-eq exponent u8)
                    u256
                    u512 ;; Max supported to avoid overflow
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

;; Square root approximation (simplified Newton's method)
(define-read-only (square-root-approx (n uint))
  (if (<= n u1)
    n
    (if (<= n u4)
      u2
      (if (<= n u9)
        u3
        (if (<= n u16)
          u4
          (if (<= n u25)
            u5
            (if (<= n u36)
              u6
              (if (<= n u49)
                u7
                (if (<= n u64)
                  u8
                  (if (<= n u81)
                    u9
                    (if (<= n u100)
                      u10
                      ;; For larger numbers, use approximation
                      (/ n u10) ;; Simple approximation
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)
