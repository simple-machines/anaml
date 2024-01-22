resource "anaml_feature" "bill_percentage_change" {
  name        = "bill_percentage_change"
  description = "Percentage change from previous month to this month."
  table       = anaml_table.bills.id
  select      = "amount"
  aggregation = "percentagechange"
  rows        = 2
}

resource "anaml_feature" "bill_amount_average" {
  name        = "bill_amount_average"
  description = "Average amount charged across all bills"
  table       = anaml_table.bills.id
  select      = "amount"
  aggregation = "avg"
}
