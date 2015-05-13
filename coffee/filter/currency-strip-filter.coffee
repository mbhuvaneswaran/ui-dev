# Strips out parenthesis for negative numbers
main.filter('currencyStrip', ['$filter', ($filter) ->
  (amount, currencySymbol) ->
    currency = $filter("currency")
    if amount < 0
      currency(amount, currencySymbol).replace("(", "").replace(")", "")
    else
      currency amount, currencySymbol
])