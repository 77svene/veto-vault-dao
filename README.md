# **🛡️ VetoVault: Optimistic Treasury Safeguard**

**Secure DAO treasuries against governance attacks by empowering long-term stakers to optimistically pause suspicious transactions during a time-locked challenge window.**

---

## 🏆 Hackonomics 2026 - DAO Tooling Track

VetoVault is a governance middleware designed to mitigate the risks of flash-loan attacks and sudden governance takeovers. By introducing a mandatory "Challenge Window" for treasury execution, it ensures that only transactions validated by long-term community commitment proceed, protecting the DAO's assets from malicious actors.

## 🚀 Tech Stack

![Solidity](https://img.shields.io/badge/Solidity-0.8.x-blue) ![Hardhat](https://img.shields.io/badge/Hardhat-2.19.0-black) ![Ethers.js](https://img.shields.io/badge/Ethers.js-6.0-green) ![Dashboard](https://img.shields.io/badge/HTML5-Responsive-orange)

## 📖 Problem & Solution

### **The Problem**
Standard DAO governance models (e.g., OpenZeppelin Governor) allow a simple majority (51%) to execute treasury transactions immediately upon vote completion. This creates critical vulnerabilities:
*   **Flash-Loan Attacks:** Bad actors borrow funds to sway a vote, drain the treasury, and repay the loan instantly.
*   **Governance Takeovers:** A sudden accumulation of voting power can drain funds before the community reacts.
*   **Lack of Cooling-Off:** There is no mechanism for long-term stakeholders to pause execution if a proposal looks suspicious.

### **The Solution**
VetoVault acts as a middleware layer between the DAO Governor and the Treasury Executor.
1.  **Challenge Window:** Every approved transaction enters a time-locked window before execution.
2.  **Staked Identity:** Only users who have staked tokens for >6 months can trigger a veto.
3.  **Bonded Veto:** Users lock a bond to challenge a transaction.
4.  **Threshold Cancellation:** If the veto threshold is met, the transaction is cancelled, and the DAO must re-vote with a higher supermajority.

## 🏗️ Architecture

```text
+----------------+       +----------------+       +----------------+
|   DAO Governor | ----> |  VetoVault     | ----> |   Treasury     |
|   (Vote Pass)  |       |  (Middleware)  |       |   (Executor)   |
+----------------+       +----------------+       +----------------+
         |                       |                       |
         |                       v                       |
         |              +----------------+               |
         |              | Challenge      |               |
         |              | Window (Time)  |               |
         |              +----------------+               |
         |                       |                       |
         v                       v                       v
+----------------+       +----------------+       +----------------+
|  Long-Term     | ----> |  Veto Bond     | ----> |  Re-Vote       |
|  Stakers       |       |  (Lock)        |       |  (Supermajor)  |
+----------------+       +----------------+       +----------------+
```

## 🛠️ Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/77svene/veto-vault-dao
cd veto-vault-dao
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Configure Environment
Create a `.env` file in the root directory with the following variables:
```env
PRIVATE_KEY=your_private_key_here
RPC_URL=https://your-rpc-provider.com
DEPLOYER_ADDRESS=0xYourAddress
```

### 4. Deploy Contracts
```bash
npx hardhat run scripts/deploy.js --network localhost
```

### 5. Run Dashboard
```bash
npm start
```
*The dashboard will open at `http://localhost:3000` to monitor pending Veto Windows.*

## 📡 API Endpoints & Contract Methods

| Method | Type | Description | Params |
| :--- | :--- | :--- | :--- |
| `propose` | External | Submit a new governance proposal | `targets`, `values`, `calldatas`, `description` |
| `queue` | External | Queue a passed proposal for execution | `proposalId` |
| `execute` | External | Execute a queued proposal | `proposalId` |
| `challenge` | External | Initiate a Veto Challenge | `proposalId`, `bondAmount` |
| `resolveChallenge` | External | Resolve challenge after timeout | `proposalId` |
| `getChallengeStatus` | View | Check current status of a challenge | `proposalId` |

## 📸 Demo Screenshots

![VetoVault Dashboard](./public/dashboard.png)
*Figure 1: Real-time monitoring of active Challenge Windows and Veto Bonds.*

![Staked Identity Verification](./public/staked-identity.png)
*Figure 2: Verification of >6 month staking requirement for veto eligibility.*

## 📂 Project Structure

```text
contracts/
├── MockDAO.sol          # Mock Governor implementation
├── StakedIdentity.sol   # Staking logic for veto eligibility
└── VetoVault.sol        # Core middleware logic
scripts/
├── deploy.js            # Deployment script
test/
└── veto_test.js         # Comprehensive test suite
public/
└── dashboard.html       # Real-time monitoring UI
hardhat.config.js        # Hardhat configuration
```

## 👥 Team

Built by **VARAKH BUILDER — autonomous AI agent**

## 📄 License

This project is licensed under the MIT License.