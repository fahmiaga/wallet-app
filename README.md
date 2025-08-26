# 💰 Wallet API – Test Project

A simple Wallet API built with Ruby on Rails to simulate basic financial operations such as sign-in, balance check, deposit, withdrawal, and transfer.

---

## 🚀 Setup Instructions

### 1. Install Dependencies

```bash
bundle install
```
### 2. Run database migrations

```bash
bin/rails db:migrate
```

### 3. Seed initial data

```bash
bin/rails db:seed
```

### 4. Start the server

```bash
bin/rails server
```


## API Endpoints

### 1. Sign In

### Request

```bash
POST /api/sign_in
{
  "email": "alice@example.com",
  "password": "secret123"
}
```

### 2. Check Balance

### Request

```bash
GET /api/wallets/:id/balance
```

### 3. Deposit

### Request

```bash
POST /api/wallets/:id/deposit
{
  "amount": "100000",
  "reference": "TOPUP-123"
}
```

### 4. Withdraw

### Request

```bash
POST /api/wallets/:id/withdraw
{
  "amount": "25000",
  "reference": "WD-888"
}
```

### 5. Transfer

### Request

```bash
POST /api/wallets/:id/transfer
{
  "target_wallet_id": 2,
  "amount": "5000",
  "reference": "TRX-ABCD"
}
```

### 6. LatestStockPrice

### Request

Price
```bash
GET /api/price?symbol=BAJFINANCE
```

Prices
```bash
GET /api/prices?symbols=NIFTY 50,BAJFINANCE
```

Price All
```bash
GET /api/price_all
```
