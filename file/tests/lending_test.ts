import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Test suite for Enhanced Lending Protocol

Clarinet.test({
    name: "Test basic deposit functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(1000000)], user1.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result.expectOk(), types.uint(1000000));
        
        // Check collateral was recorded
        let collateralCheck = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'get-collateral', [types.principal(user1.address)], deployer.address)
        ]);
        
        assertEquals(collateralCheck.receipts[0].result, types.uint(1000000));
    },
});

Clarinet.test({
    name: "Test borrowing with sufficient collateral",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // First deposit collateral
        let depositBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(1000000)], user1.address)
        ]);
        
        // Then borrow (assuming price is 100, so can borrow ~66% of collateral value)
        let borrowBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'borrow', [types.uint(600000)], user1.address)
        ]);
        
        assertEquals(borrowBlock.receipts[0].result.expectOk(), types.uint(600000));
        
        // Check debt was recorded
        let debtCheck = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'get-debt', [types.principal(user1.address)], deployer.address)
        ]);
        
        assertEquals(debtCheck.receipts[0].result, types.uint(600000));
    },
});

Clarinet.test({
    name: "Test borrowing with insufficient collateral fails",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user1 = accounts.get('wallet_1')!;
        
        // Deposit small amount
        let depositBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(100000)], user1.address)
        ]);
        
        // Try to borrow too much (should fail)
        let borrowBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'borrow', [types.uint(200000)], user1.address)
        ]);
        
        assertEquals(borrowBlock.receipts[0].result.expectErr(), types.uint(400));
    },
});

Clarinet.test({
    name: "Test repayment functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Setup: deposit and borrow
        let setupBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(1000000)], user1.address),
            Tx.contractCall('lending-protocol', 'borrow', [types.uint(600000)], user1.address)
        ]);
        
        // Repay part of the debt
        let repayBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'repay', [types.uint(300000)], user1.address)
        ]);
        
        assertEquals(repayBlock.receipts[0].result.expectOk(), types.uint(300000));
        
        // Check remaining debt
        let debtCheck = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'get-debt', [types.principal(user1.address)], deployer.address)
        ]);
        
        assertEquals(debtCheck.receipts[0].result, types.uint(300000));
    },
});

Clarinet.test({
    name: "Test collateral withdrawal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Setup: deposit collateral
        let depositBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(2000000)], user1.address)
        ]);
        
        // Borrow some amount
        let borrowBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'borrow', [types.uint(500000)], user1.address)
        ]);
        
        // Withdraw excess collateral (should be allowed)
        let withdrawBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'withdraw', [types.uint(500000)], user1.address)
        ]);
        
        assertEquals(withdrawBlock.receipts[0].result.expectOk(), types.uint(500000));
        
        // Check remaining collateral
        let collateralCheck = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'get-collateral', [types.principal(user1.address)], deployer.address)
        ]);
        
        assertEquals(collateralCheck.receipts[0].result, types.uint(1500000));
    },
});

Clarinet.test({
    name: "Test liquidation mechanism",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        const liquidator = accounts.get('wallet_2')!;
        
        // Setup: create a position close to liquidation threshold
        let setupBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(1000000)], user1.address),
            Tx.contractCall('lending-protocol', 'borrow', [types.uint(800000)], user1.address) // High leverage
        ]);
        
        // Price should be 100, so collateral value = 100M, debt = 800k
        // At current price, position should be liquidatable (100M < 800k * 120%)
        
        let liquidateBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'liquidate', [types.principal(user1.address)], liquidator.address)
        ]);
        
        // Should succeed since position is under-collateralized
        assertEquals(liquidateBlock.receipts[0].result.expectOk().expectSome().expectTuple()['liquidated'], types.bool(true));
    },
});

Clarinet.test({
    name: "Test health factor calculation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Setup position
        let setupBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(2000000)], user1.address),
            Tx.contractCall('lending-protocol', 'borrow', [types.uint(1000000)], user1.address)
        ]);
        
        // Check health factor
        let healthCheck = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'get-health-factor', [types.principal(user1.address)], deployer.address)
        ]);
        
        // Health factor should be around 166 (200M collateral value / 120M liquidation threshold)
        assertEquals(healthCheck.receipts[0].result.expectSome(), types.uint(166));
    },
});

Clarinet.test({
    name: "Test emergency pause functionality",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // Pause the contract
        let pauseBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'toggle-pause', [], deployer.address)
        ]);
        
        assertEquals(pauseBlock.receipts[0].result.expectOk(), types.bool(true));
        
        // Try to deposit while paused (should fail)
        let depositBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(1000000)], user1.address)
        ]);
        
        assertEquals(depositBlock.receipts[0].result.expectErr(), types.uint(402));
    },
});

Clarinet.test({
    name: "Test governance proposal creation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user1 = accounts.get('wallet_1')!;
        
        // First deposit collateral to get voting power
        let depositBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(2000000)], user1.address)
        ]);
        
        // Create a governance proposal
        let proposalBlock = chain.mineBlock([
            Tx.contractCall('governance', 'create-proposal', [
                types.uint(1), // proposal type
                types.ascii("Increase Min Ratio"),
                types.ascii("Proposal to increase minimum collateral ratio to 160%"),
                types.uint(160)
            ], user1.address)
        ]);
        
        assertEquals(proposalBlock.receipts[0].result.expectOk(), types.uint(1));
    },
});

Clarinet.test({
    name: "Test governance voting",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const user1 = accounts.get('wallet_1')!;
        const user2 = accounts.get('wallet_2')!;
        
        // Setup: users deposit to get voting power
        let setupBlock = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(2000000)], user1.address),
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(1500000)], user2.address)
        ]);
        
        // Create proposal
        let proposalBlock = chain.mineBlock([
            Tx.contractCall('governance', 'create-proposal', [
                types.uint(1),
                types.ascii("Test Proposal"),
                types.ascii("A test proposal for voting"),
                types.uint(160)
            ], user1.address)
        ]);
        
        // Users vote
        let voteBlock = chain.mineBlock([
            Tx.contractCall('governance', 'vote', [types.uint(1), types.bool(true)], user1.address),
            Tx.contractCall('governance', 'vote', [types.uint(1), types.bool(false)], user2.address)
        ]);
        
        assertEquals(voteBlock.receipts[0].result.expectOk(), types.bool(true));
        assertEquals(voteBlock.receipts[1].result.expectOk(), types.bool(true));
    },
});

Clarinet.test({
    name: "Test oracle price updates",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Update price (deployer is authorized by default)
        let updateBlock = chain.mineBlock([
            Tx.contractCall('oracle', 'update-price', [types.uint(120)], deployer.address)
        ]);
        
        assertEquals(updateBlock.receipts[0].result.expectOk(), types.uint(120));
        
        // Check price was updated
        let priceCheck = chain.mineBlock([
            Tx.contractCall('oracle', 'get-price', [], deployer.address)
        ]);
        
        assertEquals(priceCheck.receipts[0].result, types.uint(120));
    },
});

Clarinet.test({
    name: "Test utilities safe math operations",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Test safe multiply
        let multiplyBlock = chain.mineBlock([
            Tx.contractCall('utilities', 'safe-multiply', [types.uint(1000), types.uint(2000)], deployer.address)
        ]);
        
        assertEquals(multiplyBlock.receipts[0].result.expectSome(), types.uint(2000000));
        
        // Test percentage calculation
        let percentBlock = chain.mineBlock([
            Tx.contractCall('utilities', 'percent-of', [types.uint(1000), types.uint(15)], deployer.address)
        ]);
        
        assertEquals(percentBlock.receipts[0].result, types.uint(150));
    },
});

Clarinet.test({
    name: "Test protocol health calculation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Test protocol health with good ratios
        let healthBlock = chain.mineBlock([
            Tx.contractCall('utilities', 'calculate-protocol-health', [
                types.uint(10000000), // Total collateral
                types.uint(5000000),  // Total debt
                types.uint(100)       // Average price
            ], deployer.address)
        ]);
        
        let result = healthBlock.receipts[0].result.expectTuple();
        assertEquals(result['healthy'], types.bool(true));
        assertEquals(result['collateralization-ratio'], types.uint(200));
    },
});

// Integration test combining multiple operations
Clarinet.test({
    name: "Integration test: Full lending cycle",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        // 1. Deposit collateral
        let step1 = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'deposit', [types.uint(3000000)], user1.address)
        ]);
        
        // 2. Borrow against collateral
        let step2 = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'borrow', [types.uint(1500000)], user1.address)
        ]);
        
        // 3. Check health factor
        let step3 = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'get-health-factor', [types.principal(user1.address)], deployer.address)
        ]);
        
        // 4. Partial repayment
        let step4 = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'repay', [types.uint(750000)], user1.address)
        ]);
        
        // 5. Withdraw some collateral
        let step5 = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'withdraw', [types.uint(1000000)], user1.address)
        ]);
        
        // All operations should succeed
        assertEquals(step1.receipts[0].result.expectOk(), types.uint(3000000));
        assertEquals(step2.receipts[0].result.expectOk(), types.uint(1500000));
        assertEquals(step4.receipts[0].result.expectOk(), types.uint(750000));
        assertEquals(step5.receipts[0].result.expectOk(), types.uint(1000000));
        
        // Final position check
        let finalCheck = chain.mineBlock([
            Tx.contractCall('lending-protocol', 'get-collateral', [types.principal(user1.address)], deployer.address),
            Tx.contractCall('lending-protocol', 'get-debt', [types.principal(user1.address)], deployer.address)
        ]);
        
        assertEquals(finalCheck.receipts[0].result, types.uint(2000000)); // 3M - 1M withdrawn
        assertEquals(finalCheck.receipts[1].result, types.uint(750000));  // 1.5M - 750k repaid
    },
});
