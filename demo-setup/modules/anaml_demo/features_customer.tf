resource "anaml_feature" "customer_age" {
  name        = "customer_age"
  description = "Age of a customer as of the `feature_date`.\n\nExpressed in fractional years."
  table       = anaml_table.customer.id
  select      = "datediff(feature_date(), date_of_birth) / 365.2425"
  aggregation = "last"
}
