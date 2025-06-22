(define-map collateral (principal) uint)
(define-map debt (principal) uint)

(define-constant min-collateral-ratio u150) ;; 150%

(define-read-only (get-collateral (user principal))
  (default-to u0 (map-get? collateral user))
)

(define-read-only (get-debt (user principal))
  (default-to u0 (map-get? debt user))
)

(define-public (deposit (amount uint))
  (begin
    (map-set collateral tx-sender (+ (default-to u0 (map-get? collateral tx-sender)) amount))
    (ok amount)
  )
)

(define-public (borrow (amount uint))
  (let (
    (user-collateral (default-to u0 (map-get? collateral tx-sender)))
    (user-debt (default-to u0 (map-get? debt tx-sender)))
    (collateral-price (oracle-get-price))
    (collateral-value (* user-collateral collateral-price))
    (required-collateral (* amount min-collateral-ratio))
  )
    (if (>= collateral-value required-collateral)
        (begin
          (map-set debt tx-sender (+ user-debt amount))
          (ok amount)
        )
        (err u400)
    )
  )
)

(define-public (liquidate (user principal))
  (let (
    (collateral (default-to u0 (map-get? collateral user)))
    (debt (default-to u0 (map-get? debt user)))
    (collateral-price (oracle-get-price))
    (collateral-value (* collateral collateral-price))
    (required-collateral (* debt min-collateral-ratio))
  )
    (if (< collateral-value required-collateral)
        (begin
          (map-delete debt user)
          (map-delete collateral user)
          (ok true)
        )
        (err u401)
    )
  )
)

(define-read-only (oracle-get-price)
  (contract-call? .oracle get-price)
)
