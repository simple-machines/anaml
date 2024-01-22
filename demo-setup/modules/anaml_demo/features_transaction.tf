
resource "anaml_feature_template" "items_bought_last_n_days" {
  name        = "count_baskets_last_n_days"
  description = "The number of items a customer has bought in the past n days"
  table       = anaml_table.transactions.id
  select      = "1"
  aggregation = "count"
}

resource "anaml_feature" "items_bought_last_n_days" {
  for_each    = toset(["7", "14", "28"])
  name        = "items_bought_last_${each.key}_days"
  description = "The number of items a customer has bought in the past ${each.key} days"
  days        = parseint(each.key, 10)
  table       = anaml_table.transactions.id
  select      = "1"
  aggregation = "count"
  template    = anaml_feature_template.items_bought_last_n_days.id
}

resource "anaml_feature" "visit_count" {
  name        = "visit_count_30_days"
  description = "The number of supermarket trips a customer has had in the last 30 days.\n\n **Note**: `basket` is the id for the basket of items so `countdistinct` is used to get the number of trips."
  table       = anaml_table.transactions.id
  select      = "basket"
  aggregation = "countdistinct"
  days        = 30
}

resource "anaml_feature" "visted_any_last_14_days" {
  name             = "visted_any_last_14_days"
  description      = "Has the customer made any visits in the last 14 days?\n\nThis is useful for marketing campaigns to entice customers back with an offer."
  table            = anaml_table.transactions.id
  select           = "basket"
  aggregation      = "countdistinct"
  post_aggregation = "#AGG_RESULT# > 0"
  days             = 30
}

resource "anaml_feature" "shopping_basket_max_spend_30_days" {
  name             = "shopping_basket_max_spend_30_days"
  description      = "The maximum spend in a single trip over the last 30 days."
  table            = anaml_table.transactions.id
  select           = "named_struct('key', basket, 'value', cost)"
  aggregation      = "basketsum"
  post_aggregation = "max_basket(#AGG_RESULT#).value"
}

resource "anaml_feature" "shopping_basket_big_spender_last_30_days" {
  name        = "shopping_basket_big_spender_last_30_days"
  description = "Decides if this customer is classed as a big spender\n\n**True** if they have spend over $500 in a single transaction in the last 30 days. **False** otherwise."
  over   = [anaml_feature.shopping_basket_max_spend_30_days.id]
  entity = anaml_entity.customer.id
  select = "shopping_basket_max_spend_30_days > 500"
}

resource "anaml_feature" "items_lower_socio_economic_count_30_days" {
  name        = "items_lower_socio_economic_count_30_days"
  description = "The number of items a customer has bought categorized as lower socio economic"
  table       = anaml_table.transactions_enriched.id
  select      = "socio_economic"
  aggregation = "count"
  filter      = "socio_economic = 'L'"
  days        = 30
}
