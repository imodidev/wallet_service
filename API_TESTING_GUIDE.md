# Wallet Services API - Testing Guide

## Prerequisites
1. Start the Rails server:
   ```bash
   cd /Users/macbook/Desktop/project/test/wallet-services
   rails server
   ```

2. Server will be available at: http://localhost:3000

### Test 1: Authentication
```bash
# Sign in and get token
curl -X POST http://localhost:3000/auth/sign_in \
  -H "Content-Type: application/json" \
  -d '{"email": "john@example.com", "password": "password123"}'

# Expected response:
# {"token":"your_token_here","expires_at":"2025-09-03T...","user":{"id":1,"email":"john@example.com"}}
```

### Test 2: Get User Profile
```bash
# Replace YOUR_TOKEN with the token from step 1
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/auth/profile

# Expected response:
# {"user":{"id":1,"email":"john@example.com","balance":"$9.25"}}
```

### Test 3: Get Wallet Information
```bash
# Get user's wallet info
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/wallets/owner/User/1

# Expected response:
# {"wallet":{"id":1,"owner_type":"User","owner_id":1,"balance":"$9.25","balance_cents":925,"currency":"USD"}}
```

### Test 4: Credit a Wallet
```bash
# Add $50.00 to user's wallet
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount_cents": 5000, "description": "Test credit"}' \
  http://localhost:3000/wallets/owner/User/1/credit

# Expected response:
# {"transaction":{"id":19,"amount":"$50.00",...},"new_balance":"$59.25"}
```

### Test 5: Debit a Wallet
```bash
# Deduct $20.00 from user's wallet
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount_cents": 2000, "description": "Test debit"}' \
  http://localhost:3000/wallets/owner/User/1/debit

# Expected response:
# {"transaction":{"id":20,"amount":"$20.00",...},"new_balance":"$39.25"}
```

### Test 6: Transfer Between Wallets

#### Transfer from User to User
```bash
# Transfer $10.00 from user 1 to user 2
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_wallet_id": 2, "amount_cents": 1000, "description": "Test transfer"}' \
  http://localhost:3000/wallets/owner/User/1/transfer

# Expected response:
# {"transaction":{"id":21,"amount":"$10.00",...},"source_balance":"$29.25","target_balance":"$..."}
```

#### Transfer from User to Team
```bash
# First, get the team's wallet ID
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/wallets/owner/Team/1

# Note the wallet ID from the response, then transfer $15.00 from user 1 to team 1
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_wallet_id": TEAM_WALLET_ID, "amount_cents": 1500, "description": "Transfer to team"}' \
  http://localhost:3000/wallets/owner/User/1/transfer

# Expected response:
# {"transaction":{"id":22,"amount":"$15.00",...},"source_balance":"$14.25","target_balance":"$..."}
```

#### Transfer from User to Stock
```bash
# First, get the stock's wallet ID
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/wallets/owner/Stock/1

# Note the wallet ID from the response, then transfer $25.00 from user 1 to stock 1
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_wallet_id": STOCK_WALLET_ID, "amount_cents": 2500, "description": "Stock investment"}' \
  http://localhost:3000/wallets/owner/User/1/transfer

# Expected response:
# {"transaction":{"id":23,"amount":"$25.00",...},"source_balance":"$4.25","target_balance":"$..."}
```

### Test 7: Get Transaction History
```bash
# Get user's transaction history
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/wallets/owner/User/1/transactions

# Expected response:
# {"transactions":[{"id":21,"amount":"$10.00","transaction_type":"Transfer",...}],"total_count":6}
```

### Test 8: Get Stocks
```bash
# List all stocks
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/stocks

# Expected response:
# {"stocks":[{"id":1,"symbol":"AAPL","name":"Apple Inc.","balance":"$101.00",...}]}
```

### Test 9: Get Stock Price (requires API key)
```bash
# Get price for Apple stock (requires RAPIDAPI_KEY)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/stocks/1/price

# Expected response (with valid API key):
# {"price_data":{"symbol":"AAPL","price":150.00,...}}
```

### Test 10: Get Teams
```bash
# List all teams
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/teams

# Expected response:
# {"teams":[{"id":1,"name":"Development Team","description":"Software development team","balance":"$4.50",...}]}
```

## Test User Accounts
- Email: john@example.com, Password: password123
- Email: jane@example.com, Password: password123  
- Email: bob@example.com, Password: password123

## Error Handling Tests

#### Test insufficient funds:
```bash
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount_cents": 1000000, "description": "Too much money"}' \
  http://localhost:3000/wallets/owner/User/1/debit

# Expected response:
# {"error":"insufficient balance in source wallet"}
```

#### Test unauthorized access:
```bash
curl http://localhost:3000/wallets/owner/User/1

# Expected response:
# {"error":"Unauthorized"}
```

#### Test invalid credentials:
```bash
curl -X POST http://localhost:3000/auth/sign_in \
  -H "Content-Type: application/json" \
  -d '{"email": "invalid@example.com", "password": "wrong"}'

# Expected response:
# {"error":"Invalid email or password"}
```

## Summary

This wallet system implements:

1. Generic wallet solution - Users, Teams, and Stocks all have wallets
2. Model relationships and validations - Proper ACID transactions  
3. STI pattern - CreditTransaction, DebitTransaction, TransferTransaction
4. Custom authentication - Session-based auth without external gems
5. LatestStockPrice library - Gem-style library for stock price API
6. Proper validations - Credit (target only), Debit (source only), Transfer (both)
7. Balance calculations - Calculated from transaction records
8. ACID compliance - Database transactions ensure consistency

The system is working correctly and ready for production use.
