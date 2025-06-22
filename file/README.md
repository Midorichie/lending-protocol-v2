# Lending/Borrowing Protocol – Stacks Blockchain (Clarity)

This protocol allows users to deposit collateral and borrow against it. It includes liquidation logic if the collateral value drops below a threshold.

## Features
- Supply and borrow against collateral
- Uses mock price oracle
- Liquidation when under-collateralized

## Getting Started
1. Clone repo & install Clarinet: `curl -sSL https://get.hero.so/clarinet/install | bash`
2. Run `clarinet check` to validate Clarity code
3. Use `clarinet console` to interact with contracts

## Smart Contracts
- `lending-protocol.clar`: Core logic
- `oracle.clar`: Mock price feed
- `utils.clar`: Helper functions

## Tests
Run: `clarinet test`
