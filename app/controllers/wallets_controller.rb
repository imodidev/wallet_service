class WalletsController < ApplicationController
  before_action :set_wallet, only: [ :show, :credit, :debit, :transfer, :transactions ]

  def show
    render_success({
      wallet: {
        id: @wallet.id,
        owner_type: @wallet.owner_type,
        owner_id: @wallet.owner_id,
        balance: @wallet.balance.format,
        balance_cents: @wallet.balance_cents,
        currency: @wallet.currency
      }
    })
  end

  def credit
    amount = params[:amount_cents].to_i
    description = params[:description]

    transaction = WalletService.credit(@wallet, amount, description)

    render_success({
      transaction: transaction_json(transaction),
      new_balance: @wallet.reload.balance.format
    })
  rescue WalletService::InvalidAmountError => e
    render_error(e.message, :bad_request)
  rescue StandardError => e
    render_error(e.message)
  end

  def debit
    amount = params[:amount_cents].to_i
    description = params[:description]

    transaction = WalletService.debit(@wallet, amount, description)

    render_success({
      transaction: transaction_json(transaction),
      new_balance: @wallet.reload.balance.format
    })
  rescue WalletService::InsufficientFundsError => e
    render_error(e.message, :bad_request)
  rescue WalletService::InvalidAmountError => e
    render_error(e.message, :bad_request)
  rescue StandardError => e
    render_error(e.message)
  end

  def transfer
    target_wallet = Wallet.find(params[:target_wallet_id])
    amount = params[:amount_cents].to_i
    description = params[:description]

    transaction = WalletService.transfer(@wallet, target_wallet, amount, description)

    render_success({
      transaction: transaction_json(transaction),
      source_balance: @wallet.reload.balance.format,
      target_balance: target_wallet.reload.balance.format
    })
  rescue ActiveRecord::RecordNotFound
    render_error("Target wallet not found", :not_found)
  rescue WalletService::InsufficientFundsError => e
    render_error(e.message, :bad_request)
  rescue WalletService::InvalidAmountError => e
    render_error(e.message, :bad_request)
  rescue StandardError => e
    render_error(e.message)
  end

  def transactions
    limit = params[:limit]&.to_i || 50
    offset = params[:offset]&.to_i || 0

    transactions = WalletService.transaction_history(@wallet, limit: limit, offset: offset)

    render_success({
      transactions: transactions.map { |t| transaction_json(t) },
      total_count: @wallet.all_transactions.count
    })
  end

  private

  def set_wallet
    @wallet = case params[:owner_type]
    when "User"
                current_user.ensure_wallet!
    when "Team"
                Team.find(params[:owner_id]).ensure_wallet!
    when "Stock"
                Stock.find(params[:owner_id]).ensure_wallet!
    else
                Wallet.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_error("Wallet not found", :not_found)
  end

  def transaction_json(transaction)
    {
      id: transaction.id,
      amount: transaction.amount.format,
      amount_cents: transaction.amount_cents,
      transaction_type: transaction.transaction_type,
      status: transaction.status,
      description: transaction.description,
      source_wallet_id: transaction.source_wallet_id,
      target_wallet_id: transaction.target_wallet_id,
      created_at: transaction.created_at
    }
  end
end
