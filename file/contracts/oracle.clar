;; Dummy oracle that returns fixed price

(define-constant price u1)

(define-read-only (get-price)
  price
)
