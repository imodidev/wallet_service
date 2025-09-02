# Wallet Services

Internal digital wallet system built with Ruby on Rails API for managing wallets across multiple entities (Users, Teams, Stocks) with transaction tracking and ACID compliance.

## Features

- Multi-entity wallet system for Users, Teams, and Stocks
- Polymorphic associations - any entity can have a wallet
- Real-time balance calculation from transaction history
- Three transaction types using STI pattern:
  - Credit Transactions - Deposits/Top-ups
  - Debit Transactions - Withdrawals
  - Transfer Transactions - Inter-wallet transfers
- Session-based authentication without external gems
- Token expiration (24 hours)
- ACID compliance with database transactions
- Complete audit trail for all operations
- Balance validation to prevent overdrafts
- Stock price integration via LatestStockPrice library
- JSON API responses

## Architecture

### Database Design
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│    Users    │    │    Teams     │    │   Stocks    │
├─────────────┤    ├──────────────┤    ├─────────────┤
│ id          │    │ id           │    │ id          │
│ email       │    │ name         │    │ symbol      │
│ password    │    │ created_at   │    │ name        │
└─────────────┘    └──────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │ (polymorphic)
                    ┌──────▼──────┐
                    │   Wallets   │
                    ├─────────────┤
                    │ id          │
                    │ owner_type  │
                    │ owner_id    │
                    │ balance_cents│
                    │ currency    │
                    └─────────────┘
                           │
                    ┌──────▼──────┐
                    │Transactions │ (STI)
                    ├─────────────┤
                    │ id          │
                    │ type        │ ← Credit/Debit/Transfer
                    │ amount_cents│
                    │ source_wallet_id │
                    │ target_wallet_id │
                    │ status      │
                    │ description │
                    └─────────────┘
```

### Service Layer
```ruby
WalletService
├── .credit(wallet, amount, description)
├── .debit(wallet, amount, description)  
├── .transfer(source, target, amount, description)
├── .balance(wallet)
└── .transaction_history(wallet)
```

## Installation & Setup

### Prerequisites
- Ruby 3.3.6
- Rails 8.0.2.1
- PostgreSQL
- Bundler

### Installation Steps

1. Clone the repository
```bash
git clone <repository-url>
cd wallet-services
```

2. Install dependencies
```bash
bundle install
```

3. Setup database
```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# Seed with test data
rails db:seed
```

4. Start the server
```bash
rails server
# Server runs on http://localhost:3000
```

## Testing

### Run Test Suite
```bash
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/models/wallet_spec.rb
```

### Test Coverage
- 86 examples, 0 failures
- Model validations and associations
- Service layer business logic  
- API endpoints and authentication
- Transaction flows and balance calculations

### Manual API Testing
```bash
# Test all services
ruby scripts/test_all_services.rb

# Individual operations
ruby scripts/test_credit_operation.rb
ruby scripts/test_debit_operation.rb
ruby scripts/test_transfer_operation.rb
```

## API Documentation

For complete API testing examples and detailed guides, see: [API_TESTING_GUIDE.md](API_TESTING_GUIDE.md)

### Authentication
```bash
# Sign in
POST /auth/sign_in
Content-Type: application/json
{
  "email": "john@example.com",
  "password": "password123"
}

# Get profile (requires token)
GET /auth/profile
Authorization: Bearer <token>
```

### Wallet Operations
```bash
# Get wallet info
GET /wallets/:id
Authorization: Bearer <token>

# Credit wallet
POST /wallets/:id/credit
Authorization: Bearer <token>
Content-Type: application/json
{
  "amount_cents": 5000,
  "description": "Deposit"
}

# Debit wallet  
POST /wallets/:id/debit
Authorization: Bearer <token>
Content-Type: application/json
{
  "amount_cents": 2000,
  "description": "Withdrawal"
}

# Transfer between wallets
POST /wallets/:id/transfer
Authorization: Bearer <token>
Content-Type: application/json
{
  "target_wallet_id": 2,
  "amount_cents": 3000,
  "description": "Transfer to team"
}

# Transaction history
GET /wallets/:id/transactions
Authorization: Bearer <token>
```

## Configuration

### Environment Variables
```bash
# Database
DATABASE_NAME=wallet_services
DATABASE_USERNAME=macbook
DATABASE_PASSWORD=
DATABASE_HOST=localhost

# Stock API (optional)
RAPIDAPI_KEY=your_rapidapi_key_here
```

### Database Configuration
Located in `config/database.yml` - configured for PostgreSQL with environment variable support.

## Project Structure

```
wallet-services/
├── app/
│   ├── controllers/          # API controllers
│   │   ├── auth_controller.rb
│   │   ├── wallets_controller.rb
│   │   ├── stocks_controller.rb
│   │   └── teams_controller.rb
│   ├── models/              # Core business models
│   │   ├── user.rb
│   │   ├── wallet.rb
│   │   ├── transaction.rb   # STI base class
│   │   ├── credit_transaction.rb
│   │   ├── debit_transaction.rb
│   │   ├── transfer_transaction.rb
│   │   ├── session.rb
│   │   ├── team.rb
│   │   └── stock.rb
│   └── services/            # Business logic
│       └── wallet_service.rb
├── lib/
│   └── latest_stock_price/  # Custom stock price library
│       ├── latest_stock_price.rb
│       ├── client.rb
│       └── version.rb
├── spec/                    # RSpec tests
│   ├── models/
│   ├── services/
│   ├── requests/
│   └── factories/
├── scripts/                 # Testing utilities
│   ├── test_all_services.rb
│   ├── test_credit_operation.rb
│   ├── test_debit_operation.rb
│   └── test_transfer_operation.rb
└── API_TESTING_GUIDE.md     # Complete API testing guide
```

## Usage Examples

### Basic Wallet Operations

```ruby
# Create wallets (automatic via ensure_wallet!)
user = User.find_by(email: 'john@example.com')
user_wallet = user.ensure_wallet!

team = Team.find_by(name: 'Marketing')
team_wallet = team.ensure_wallet!

# Credit operation
WalletService.credit(user_wallet, 10000, 'Initial deposit')
# => User wallet balance: $100.00

# Debit operation  
WalletService.debit(user_wallet, 2000, 'Withdrawal')
# => User wallet balance: $80.00

# Transfer operation
WalletService.transfer(user_wallet, team_wallet, 3000, 'Team funding')
# => User wallet: $50.00, Team wallet: $30.00

# Check balance
WalletService.balance(user_wallet)
# => #<Money fractional:5000 currency:USD>

# Transaction history
WalletService.transaction_history(user_wallet)
# => [<Transaction>, <Transaction>, ...]
```

### Stock Integration

```ruby
# Get stock price (requires API key)
LatestStockPrice.price('AAPL')

# Get multiple stock prices
LatestStockPrice.prices('AAPL', 'GOOGL', 'MSFT')

# Get all stock prices
LatestStockPrice.price_all
```

## Database

### Test Credentials
- Users: john@example.com, jane@example.com, bob@example.com
- Password: password123 (for all users)
- Teams: Marketing, Engineering, Sales
- Stocks: AAPL, GOOGL, MSFT

### Database Access
```bash
# Connect to development database
psql -d wallet_services_development

# View all wallets
SELECT * FROM wallets;

# View all transactions  
SELECT * FROM transactions;
```

## Development

### Code Style
- Follow Rails conventions
- Use RuboCop for code styling
- Write comprehensive tests for new features

### Adding New Features
1. Create tests first (TDD approach)
2. Implement feature
3. Update API documentation
4. Add manual testing scripts

### Database Migrations
```bash
# Generate migration
rails generate migration AddColumnToTable column:type

# Run migration
rails db:migrate

# Rollback migration
rails db:rollback
```

## Requirements Fulfilled

- Generic wallet solution for multiple entity types
- Database records for all credit/debit operations with validations
- STI pattern implementation for transaction types
- ACID compliance with proper transaction wrapping
- Balance calculation from transaction records
- Custom authentication without external gems
- LatestStockPrice library for stock price integration

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- Create an issue in the repository
- Check the [API Testing Guide](API_TESTING_GUIDE.md)
