;; Enhanced Oracle Contract with Price Feeds and Security

(define-constant contract-owner tx-sender)
(define-constant err-unauthorized u100)
(define-constant err-invalid-price u101)
(define-constant err-stale-price u102)

;; Price data structure
(define-map price-feeds (string-ascii 10) {
  price: uint,
  last-updated: uint,
  deviation: uint
})

;; Authorized price updaters - Fixed map definition
(define-map price-updaters principal bool)

;; Default price and update frequency
(define-data-var base-price uint u100) ;; Base price in micro-units
(define-data-var max-price-age uint u144) ;; ~24 hours in blocks (assuming 10min blocks)
(define-data-var price-change-limit uint u20) ;; Max 20% price change per update

;; Initialize contract
(map-set price-feeds "STX-USD" {
  price: u100,
  last-updated: block-height,
  deviation: u0
})

(map-set price-updaters contract-owner true)

;; Read-only functions
(define-read-only (get-price)
  (let (
    (feed-data (unwrap-panic (map-get? price-feeds "STX-USD")))
    (current-price (get price feed-data))
    (last-update (get last-updated feed-data))
  )
    (if (< (- block-height last-update) (var-get max-price-age))
        current-price
        (var-get base-price) ;; Fallback to base price if stale
    )
  )
)

(define-read-only (get-price-with-metadata)
  (map-get? price-feeds "STX-USD")
)

(define-read-only (is-price-stale)
  (let (
    (feed-data (unwrap-panic (map-get? price-feeds "STX-USD")))
    (last-update (get last-updated feed-data))
  )
    (> (- block-height last-update) (var-get max-price-age))
  )
)

(define-read-only (get-price-age)
  (let (
    (feed-data (unwrap-panic (map-get? price-feeds "STX-USD")))
    (last-update (get last-updated feed-data))
  )
    (- block-height last-update)
  )
)

;; Price update function with validation
(define-public (update-price (new-price uint))
  (begin
    (asserts! (default-to false (map-get? price-updaters tx-sender)) (err err-unauthorized))
    (asserts! (> new-price u0) (err err-invalid-price))
    
    (let (
      (current-data (unwrap-panic (map-get? price-feeds "STX-USD")))
      (current-price (get price current-data))
      (price-change (if (> new-price current-price)
                      (/ (* (- new-price current-price) u100) current-price)
                      (/ (* (- current-price new-price) u100) current-price)))
    )
      ;; Validate price change isn't too extreme
      (asserts! (<= price-change (var-get price-change-limit)) (err err-invalid-price))
      
      ;; Update price feed
      (map-set price-feeds "STX-USD" {
        price: new-price,
        last-updated: block-height,
        deviation: price-change
      })
      
      (ok new-price)
    )
  )
)

;; Admin functions
(define-public (add-price-updater (updater principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-unauthorized))
    (map-set price-updaters updater true)
    (ok true)
  )
)

(define-public (remove-price-updater (updater principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-unauthorized))
    (map-delete price-updaters updater)
    (ok true)
  )
)

(define-public (set-max-price-age (new-age uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-unauthorized))
    (var-set max-price-age new-age)
    (ok new-age)
  )
)

(define-public (set-price-change-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-unauthorized))
    (var-set price-change-limit new-limit)
    (ok new-limit)
  )
)

;; Emergency price reset
(define-public (emergency-price-reset (emergency-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-unauthorized))
    (asserts! (> emergency-price u0) (err err-invalid-price))
    
    (map-set price-feeds "STX-USD" {
      price: emergency-price,
      last-updated: block-height,
      deviation: u0
    })
    (ok emergency-price)
  )
)
