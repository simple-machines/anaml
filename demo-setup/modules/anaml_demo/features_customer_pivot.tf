resource "anaml_feature" "plan_customer" {
  name        = "plan_customer"
  description = "Customer for a plan"
  table       = anaml_table.plans.id
  select      = "customer"
  aggregation = "last"
}
