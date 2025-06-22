;; Governance Contract for Lending Protocol
;; Allows community voting on protocol parameters

(define-constant contract-owner tx-sender)
(define-constant voting-period u1008) ;; ~1 week in blocks
(define-constant min-voting-power u1000) ;; Minimum tokens to create proposal

;; Error constants
(define-constant err-unauthorized u200)
(define-constant err-proposal-not-found u201)
(define-constant err-voting-ended u202)
(define-constant err-already-voted u203)
(define-constant err-insufficient-voting-power u204)
(define-constant err-proposal-not-executable u205)

;; Proposal types
(define-constant proposal-type-collateral-ratio u1)
(define-constant proposal-type-liquidation-threshold u2)
(define-constant proposal-type-max-loan-amount u3)

;; Data structures
(define-map proposals uint {
  proposer: principal,
  proposal-type: uint,
  title: (string-ascii 50),
  description: (string-ascii 200),
  new-value: uint,
  created-at: uint,
  voting-ends: uint,
  votes-for: uint,
  votes-against: uint,
  executed: bool
})

(define-map user-votes {proposal-id: uint, voter: principal} {power: uint, choice: bool})
(define-map user-voting-power principal uint)

;; Contract state
(define-data-var next-proposal-id uint u1)
(define-data-var total-voting-power uint u0)

;; Admin function to set voting power (for testing - remove in production)
(define-public (set-voting-power (user principal) (power uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-unauthorized))
    (map-set user-voting-power user power)
    (ok power)
  )
)

;; Mock voting power based on collateral (in real implementation, this would be token-based)
;; For now, we'll use a simple fallback since contract resolution needs to be handled at deployment
(define-read-only (get-voting-power (user principal))
  ;; In a real implementation, this would call the lending protocol
  ;; For now, return a default value to avoid contract resolution issues
  ;; This should be updated after deployment with proper contract addresses
  (default-to u0 (map-get? user-voting-power user))
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-user-vote (proposal-id uint) (voter principal))
  (map-get? user-votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (get-user-vote proposal-id voter))
)

;; Create a new proposal
(define-public (create-proposal (proposal-type uint) (title (string-ascii 50)) (description (string-ascii 200)) (new-value uint))
  (let (
    (proposer-power (get-voting-power tx-sender))
    (proposal-id (var-get next-proposal-id))
  )
    (asserts! (>= proposer-power min-voting-power) (err err-insufficient-voting-power))
    
    (map-set proposals proposal-id {
      proposer: tx-sender,
      proposal-type: proposal-type,
      title: title,
      description: description,
      new-value: new-value,
      created-at: block-height,
      voting-ends: (+ block-height voting-period),
      votes-for: u0,
      votes-against: u0,
      executed: false
    })
    
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (support bool))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) (err err-proposal-not-found)))
    (voter-power (get-voting-power tx-sender))
    (voting-ends (get voting-ends proposal))
  )
    (asserts! (> voter-power u0) (err err-insufficient-voting-power))
    (asserts! (<= block-height voting-ends) (err err-voting-ended))
    (asserts! (not (has-voted proposal-id tx-sender)) (err err-already-voted))
    
    ;; Record the vote
    (map-set user-votes {proposal-id: proposal-id, voter: tx-sender} {
      power: voter-power,
      choice: support
    })
    
    ;; Update proposal vote counts
    (if support
      (map-set proposals proposal-id 
        (merge proposal {votes-for: (+ (get votes-for proposal) voter-power)}))
      (map-set proposals proposal-id 
        (merge proposal {votes-against: (+ (get votes-against proposal) voter-power)}))
    )
    
    (ok true)
  )
)

;; Execute a proposal (simplified - in real implementation would call other contracts)
(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) (err err-proposal-not-found)))
    (voting-ends (get voting-ends proposal))
    (votes-for (get votes-for proposal))
    (votes-against (get votes-against proposal))
    (executed (get executed proposal))
  )
    (asserts! (> block-height voting-ends) (err err-voting-ended))
    (asserts! (not executed) (err err-proposal-not-executable))
    (asserts! (> votes-for votes-against) (err err-proposal-not-executable))
    
    ;; Mark as executed
    (map-set proposals proposal-id (merge proposal {executed: true}))
    
    ;; In a real implementation, this would call the main contract to update parameters
    ;; For now, we just return success with the proposed change
    (ok {
      proposal-type: (get proposal-type proposal),
      new-value: (get new-value proposal),
      executed: true
    })
  )
)

;; Get proposal status
(define-read-only (get-proposal-status (proposal-id uint))
  (match (get-proposal proposal-id)
    proposal (let (
      (voting-ends (get voting-ends proposal))
      (votes-for (get votes-for proposal))
      (votes-against (get votes-against proposal))
      (total-votes (+ votes-for votes-against))
    )
      (some {
        active: (<= block-height voting-ends),
        winning: (> votes-for votes-against),
        participation: total-votes,
        executed: (get executed proposal)
      })
    )
    none
  )
)

;; Get all proposals (limited to last 10 for gas efficiency)
(define-read-only (get-recent-proposals)
  (let (
    (current-id (var-get next-proposal-id))
    (start-id (if (> current-id u10) (- current-id u10) u1))
  )
    {
      total-proposals: (- current-id u1),
      start-id: start-id,
      end-id: (- current-id u1)
    }
  )
)
