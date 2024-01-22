resource "anaml_feature" "plan_size" {
  name        = "plan_size"
  description = "What plan size is the customer on? Categorical feature, valid entries are: S, M L"
  table       = anaml_table.plans.id
  select      = "size"
  aggregation = "last"
}

resource "anaml_feature" "plan_age" {
  name        = "plan_age"
  description = "Plan age"
  table       = anaml_table.plans.id
  select      = "datediff(feature_date(), start_date)"
  aggregation = "last"
}
