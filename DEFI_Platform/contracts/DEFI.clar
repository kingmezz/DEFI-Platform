;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-POOL-NOT-FOUND (err u104))
(define-constant ERR-LIQUIDATION-FAILED (err u105))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u106))
(define-constant ERR-INVALID-VOTE (err u107))

;; Data variables
(define-data-var minimum-collateral-ratio uint u150) ;; 150% collateral ratio
(define-data-var platform-fee uint u1) ;; 0.1% fee in basis points
(define-data-var total-liquidity uint u0)
(define-data-var governance-token-name (string-ascii 32) "GOVTOKEN")
(define-data-var proposal-count uint u0)
(define-data-var liquidation-penalty uint u10) ;; 10% penalty
(define-data-var total-staked uint u0)

;; Data maps
(define-map user-balances 
    principal 
    {
        deposited: uint,
        borrowed: uint,
        collateral: uint,
        staked: uint,
        rewards: uint,
        governance-tokens: uint,
        last-reward-claim: uint
    }
)

(define-map lending-pools 
    (string-ascii 32) 
    {
        total-supplied: uint,
        total-borrowed: uint,
        interest-rate: uint,
        collateral-factor: uint,
        reward-rate: uint,
        last-update-time: uint
    }
)

(define-map governance-proposals
    uint
    {
        proposer: principal,
        description: (string-ascii 256),
        for-votes: uint,
        against-votes: uint,
        start-block: uint,
        end-block: uint,
        executed: bool
    }
)

(define-map staking-pools
    (string-ascii 32)
    {
        total-staked: uint,
        reward-rate: uint,
        last-update-time: uint,
        reward-per-token: uint
    }
)

(define-map user-votes
    { user: principal, proposal-id: uint }
    { voted: bool, vote: bool }
)

;; Staking Functions

(define-public (stake (amount uint) (pool-name (string-ascii 32)))
    (let (
        (user-balance (unwrap! (map-get? user-balances tx-sender) (err u404)))
        (pool (unwrap! (map-get? staking-pools pool-name) (err u404)))
    )
    (begin
        ;; Update user staking balance
        (map-set user-balances tx-sender 
            (merge user-balance {
                staked: (+ (get staked user-balance) amount)
            })
        )
        ;; Update pool
        (map-set staking-pools pool-name
            (merge pool {
                total-staked: (+ (get total-staked pool) amount),
                last-update-time: block-height
            })
        )
        (var-set total-staked (+ (var-get total-staked) amount))
        (ok true)
    ))
)

(define-public (unstake (amount uint) (pool-name (string-ascii 32)))
    (let (
        (user-balance (unwrap! (map-get? user-balances tx-sender) (err u404)))
        (pool (unwrap! (map-get? staking-pools pool-name) (err u404)))
    )
    (if (>= (get staked user-balance) amount)
        (begin
            ;; Claim rewards before unstaking
            (try! (claim-staking-rewards pool-name))
            ;; Update user staking balance
            (map-set user-balances tx-sender 
                (merge user-balance {
                    staked: (- (get staked user-balance) amount)
                })
            )
            ;; Update pool
            (map-set staking-pools pool-name
                (merge pool {
                    total-staked: (- (get total-staked pool) amount),
                    last-update-time: block-height
                })
            )
            (var-set total-staked (- (var-get total-staked) amount))
            (ok true)
        )
        ERR-INSUFFICIENT-BALANCE
    ))
)

;; Reward Functions

(define-public (claim-staking-rewards (pool-name (string-ascii 32)))
    (let (
        (user-balance (unwrap! (map-get? user-balances tx-sender) (err u404)))
        (pool (unwrap! (map-get? staking-pools pool-name) (err u404)))
        (rewards-earned (calculate-rewards tx-sender pool-name))
    )
    (begin
        (map-set user-balances tx-sender 
            (merge user-balance {
                rewards: (+ (get rewards user-balance) rewards-earned),
                last-reward-claim: block-height
            })
        )
        (ok rewards-earned)
    ))
)
