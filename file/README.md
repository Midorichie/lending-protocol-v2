# Enhanced Lending Protocol v2.0

A comprehensive decentralized lending protocol built on Stacks blockchain using Clarity smart contracts. This protocol enables users to deposit collateral, borrow against it, and participate in governance decisions.

## 🚀 Features

### Core Lending Features
- **Collateralized Lending**: Deposit STX as collateral and borrow against it
- **Dynamic Liquidations**: Automated liquidation system with penalty mechanisms
- **Health Factor Monitoring**: Real-time position health tracking
- **Flexible Repayment**: Partial and full debt repayment options
- **Collateral Withdrawal**: Withdraw excess collateral while maintaining healthy positions

### Security Enhancements
- **Emergency Pause**: Contract-wide pause mechanism for emergency situations
- **Position Limits**: Maximum loan amounts to prevent excessive risk
- **Oracle Validation**: Price feed validation with staleness checks
- **Access Controls**: Role-based permissions for critical functions
- **Overflow Protection**: Safe math operations throughout

### Governance System
- **Community Proposals**: Token holders can propose protocol changes
- **Voting Mechanism**: Weighted voting based on collateral positions
- **Parameter Updates**: Vote on collateral ratios, liquidation thresholds, and loan limits
- **Execution System**: Automatic proposal execution after successful votes

### Advanced Oracle
- **Price Feed Management**: Multiple price feed support with metadata
- **Staleness Protection**: Automatic fallback to base prices for stale data
- **Price Change Limits**: Protection against extreme price manipulation
- **Emergency Controls**: Owner-controlled emergency price updates

## �� Contract Architecture

### Main Contracts

1. **lending-protocol.clar** - Core lending logic
2. **oracle.clar** - Price feed management
3. **governance.clar** - Community governance system
4. **utilities.clar** - Mathematical and helper functions

### Key Parameters

- **Minimum Collateral Ratio**: 150%
- **Liquidation Threshold**: 120%
- **Maximum Loan Amount**: 1,000,000 units
- **Liquidation Penalty**: 10%
- **Governance Voting Period**: ~1 week (1,008 blocks)

## 🔧 Phase 2 Improvements

### Bugs Fixed
1. **Oracle Error Handling**: Added proper error handling for oracle failures
2. **Division by Zero**: Protected against division by zero in ratio calculations
3. **Integer Overflow**: Implemented safe math operations
4. **Missing Validations**: Added comprehensive input validation
5. **State Consistency**: Fixed map consistency issues between collateral/debt and user-positions

### New Functionality
1. **Repay Function**: Allow users to repay debt partially or fully
2. **Withdraw Function**: Enable collateral withdrawal with health checks
3. **Health Factor Calculation**: Real-time position health monitoring
4. **Emergency Pause**: Contract-wide pause mechanism
5. **Position Tracking**: Comprehensive user position management

### Security Enhancements
1. **Access Controls**: Role-based permissions throughout
2. **Rate Limiting**: Maximum loan amounts and price change limits
3. **Oracle Security**: Multi-layered price feed validation
4. **Emergency Controls**: Owner-controlled emergency functions
5. **Input Validation**: Comprehensive parameter validation

### New Governance Contract
- Community-driven parameter updates
- Weighted voting system
- Proposal creation and execution
- Transparent governance process

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity and Stacks blockchain

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd enhanced-lending-protocol
```

2. Install dependencies:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

### Deployment

1. Configure your deployment settings in `Clarinet.toml`
2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

## �� Usage Examples

### Basic Lending Operations

#### Deposit Collateral
```clarity
(contract-call? .lending-protocol deposit u1000000) ;; Deposit 1 STX as collateral
```

#### Borrow Against Collateral
```clarity
(contract-call? .lending-protocol borrow u500000) ;; Borrow 0.5 STX worth
```

#### Check Position Health
```clarity
(contract-call? .lending-protocol get-health-factor tx-sender)
```

#### Repay Debt
```clarity
(contract-call? .lending-protocol repay u250000) ;; Repay 0.25 STX worth
```

#### Withdraw Collateral
```clarity
(contract-call? .lending-protocol withdraw u200000) ;; Withdraw 0.2 STX collateral
```

### Governance Operations

#### Create Proposal
```clarity
(contract-call? .governance create-proposal 
  u1 ;; Proposal type (collateral ratio)
  "Increase Min Ratio"
  "Proposal to increase minimum collateral ratio to 160%"
  u160) ;; New value
```

#### Vote on Proposal
```clarity
(contract-call? .governance vote u1 true) ;; Vote yes on proposal #1
```

### Oracle Operations

#### Update Price (Authorized users only)
```clarity
(contract-call? .oracle update-price u120) ;; Update STX price to $1.20
```

#### Check Price Staleness
```clarity
(contract-call? .oracle is-price-stale)
```

## 🧪 Testing

The protocol includes comprehensive tests covering:
- Basic lending operations
- Edge cases and error conditions
- Security scenarios
- Governance workflows
- Oracle functionality

Run the test suite:
```bash
clarinet test
```

## 🔒 Security Considerations

### Risk Management
- All positions are overcollateralized (minimum 150%)
- Automatic liquidation prevents bad debt
- Price feed validation prevents manipulation
- Emergency pause protects against critical issues

### Access Control
- Contract owner has emergency powers only
- Governance decisions require community consensus
- Oracle updates require authorized accounts
- User funds are always protected

### Audit Recommendations
- Regular security audits recommended
- Monitor for unusual trading patterns
- Keep oracle price feeds updated
- Maintain emergency response procedures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

### Development Guidelines
- Follow Clarity best practices
- Include comprehensive tests
- Document all functions
- Use consistent naming conventions

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)

## 📞 Support

For questions and support:
- Create an issue on GitHub
- Join our Discord community
- Check the documentation wiki

---

**⚠️ Disclaimer**: This protocol is for educational and development purposes. Always conduct thorough testing and security audits before deploying to mainnet with real funds.
