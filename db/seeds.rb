# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
#
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample users
users_data = [
  { email: 'john@example.com', password: 'password123' },
  { email: 'jane@example.com', password: 'password123' },
  { email: 'bob@example.com', password: 'password123' }
]

users = users_data.map do |user_data|
  User.find_or_create_by!(email: user_data[:email]) do |user|
    user.password = user_data[:password]
    user.password_confirmation = user_data[:password]
  end
end

# Ensure each user has a wallet
users.each do |user|
  existing_wallet = Wallet.find_by(owner_type: 'User', owner_id: user.id)
  unless existing_wallet
    Wallet.create!(owner_type: 'User', owner_id: user.id)
  end
end

puts "Created #{users.count} users"

# Create sample teams
teams_data = [
  { name: 'Development Team', description: 'Software development team' },
  { name: 'Marketing Team', description: 'Marketing and sales team' },
  { name: 'Finance Team', description: 'Financial operations team' }
]

teams = teams_data.map do |team_data|
  Team.find_or_create_by!(name: team_data[:name]) do |team|
    team.description = team_data[:description]
  end
end

# Ensure each team has a wallet
teams.each do |team|
  existing_wallet = Wallet.find_by(owner_type: 'Team', owner_id: team.id)
  unless existing_wallet
    Wallet.create!(owner_type: 'Team', owner_id: team.id)
  end
end

puts "Created #{teams.count} teams"

# Create sample stocks
stocks_data = [
  { symbol: 'AAPL', name: 'Apple Inc.' },
  { symbol: 'GOOGL', name: 'Alphabet Inc.' },
  { symbol: 'MSFT', name: 'Microsoft Corporation' },
  { symbol: 'TSLA', name: 'Tesla, Inc.' },
  { symbol: 'AMZN', name: 'Amazon.com, Inc.' }
]

stocks = stocks_data.map do |stock_data|
  Stock.find_or_create_by!(symbol: stock_data[:symbol]) do |stock|
    stock.name = stock_data[:name]
  end
end

# Ensure each stock has a wallet
stocks.each do |stock|
  existing_wallet = Wallet.find_by(owner_type: 'Stock', owner_id: stock.id)
  unless existing_wallet
    Wallet.create!(owner_type: 'Stock', owner_id: stock.id)
  end
end

puts "Created #{stocks.count} stocks"

# Add some initial balance to user wallets
users.each do |user|
  if user.wallet.balance_cents == 0
    WalletService.credit(user.wallet, 100000, 'Initial balance') # $1000
  end
end

puts "Added initial balances to user wallets"

# Add some balance to team wallets
teams.each do |team|
  if team.wallet.balance_cents == 0
    WalletService.credit(team.wallet, 50000, 'Initial team budget') # $500
  end
end

puts "Added initial balances to team wallets"

# Add some balance to stock wallets (for trading simulation)
stocks.each do |stock|
  if stock.wallet.balance_cents == 0
    WalletService.credit(stock.wallet, 1000000, 'Initial stock reserves') # $10000
  end
end

puts "Added initial balances to stock wallets"

# Create some sample transactions
puts "Creating sample transactions..."

# Transfer from user to team
WalletService.transfer(users.first.wallet, teams.first.wallet, 5000, 'Project funding')

# Transfer between users
WalletService.transfer(users.first.wallet, users.second.wallet, 2500, 'Personal transfer')

# Debit from user (withdrawal)
WalletService.debit(users.second.wallet, 1000, 'ATM withdrawal')

# Transfer from team to stock (investment)
WalletService.transfer(teams.first.wallet, stocks.first.wallet, 10000, 'Stock purchase')

puts "Sample transactions created"

puts "
Seed data creation completed!"
puts "You can sign in with any of these users:"
users_data.each do |user_data|
  puts "  Email: #{user_data[:email]}, Password: #{user_data[:password]}"
end
