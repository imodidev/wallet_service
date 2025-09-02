# encoding : utf-8

MoneyRails.configure do |config|

  # To set the default currency
  config.default_currency = :usd

  # Set default money format globally.
  config.default_format = {
    no_cents_if_whole: nil,
    symbol: nil,
    sign_before_symbol: nil
  }

  # For the legacy behaviour of "per currency" localization (formatting depends
  # only on currency):
  config.locale_backend = :currency

  # Set default raise_error_on_money_parsing option
  config.raise_error_on_money_parsing = false
end

# Set the global default currency
Money.default_currency = Money::Currency.new('USD')
