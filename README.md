# KorenX Token Airdrop System

A secure ERC20 token distribution system with whitelist-based claiming mechanism.

## 🎯 Features

- **ERC20 Token** - Fixed supply of 1,000,000 tokens
- **Whitelist-based Distribution** - Owner controls recipient list
- **User-initiated Claims** - Gas-efficient claiming mechanism
- **Time-bound Airdrops** - Configurable claim windows
- **Emergency Controls** - Pausable functionality
- **Comprehensive Testing** - 49 unit tests with 100% pass rate

## 📊 Project Structure
```
├── src/
│   ├── KorenX.sol      # ERC20 Token Contract
│   └── Airdrop.sol     # Distribution Contract
├── test/
│   ├── KorenX.t.sol    # Token Tests (18 tests)
│   └── Airdrop.t.sol   # Airdrop Tests (31 tests)
├── script/
│   ├── DeployKorenX.s.sol        # Deployment script
│   ├── SetupWhitelist.s.sol      # Whitelist configuration
│   └── StartAirdrop.s.sol        # Airdrop activation
└── lib/                # Dependencies (OpenZeppelin, Forge)
```

## 🧪 Testing
```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run with gas report
forge test --gas-report

# Run coverage
forge coverage
```

**Test Results:**
- Total Tests: 49
- Passed: 49 ✅
- Failed: 0 ❌

## 🚀 Deployment

### Local Deployment (Anvil)
```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export RPC_URL=http://127.0.0.1:8545

forge script script/DeployKorenX.s.sol:DeployKorenX --rpc-url $RPC_URL --broadcast
```

### Testnet Deployment
```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export RPC_URL=your_sepolia_rpc_url

# Deploy contracts
forge script script/DeployKorenX.s.sol:DeployKorenX --rpc-url $RPC_URL --broadcast --verify
```

## 🔒 Security Features

- ✅ OpenZeppelin audited libraries
- ✅ Reentrancy protection (SafeERC20)
- ✅ Access control (Ownable)
- ✅ Double-claim prevention
- ✅ Input validation
- ✅ Pausable mechanism

## 📖 Contracts

### KorenX Token
- Standard ERC20 implementation
- Fixed supply: 1,000,000 tokens
- 18 decimals
- Owner-controlled airdrop integration

### Airdrop Contract
- Whitelist management
- Claim validation
- Time-bound distributions
- Token recovery after expiry

## 🛠️ Technology Stack

- **Solidity** 0.8.30
- **Foundry** - Development framework
- **OpenZeppelin** - Security libraries
- **Anvil** - Local testing

## 📄 License

MIT

## 👨‍💻 Author

[Your Name]

## 🔗 Deployed Contracts

**Local (Anvil):**
- Token: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- Airdrop: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`

**Testnet (Sepolia):**
- Coming soon...
