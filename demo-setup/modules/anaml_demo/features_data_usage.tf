
# Domains
# = Other
# | Social
# | Music
# | Sport
# | News
# | Video

resource "anaml_feature" "data_usage_daily_maximum_last_30_days" {
  name        = "data_usage_daily_maximum_last_30_days"
  description = "Maximum daily data usage over the last 30 days"
  table       = anaml_table.data_usage.id
  select      = "megabytes"
  aggregation = "max"
  days        = 30
}

resource "anaml_feature_template" "sport_data_usage_last_n_days" {
  name        = "sport_data_usage_last_n_days"
  description = "Total data usage for sport over the last n days"
  table       = anaml_table.data_usage.id
  select      = "megabytes"
  filter      = "domain = 'sport'"
  aggregation = "sum"
}

resource "anaml_feature" "sport_data_usage_last_n_days" {
  for_each    = toset(["7", "28"])
  name        = "sport_data_usage_last_${each.key}_days"
  description = "Total data usage for major sporting apps and websites over the last ${each.key} days"
  table       = anaml_table.data_usage.id
  select      = "megabytes"
  filter      = "domain = 'sport'"
  aggregation = "sum"
  days        = parseint(each.key, 10)
  template    = anaml_feature_template.sport_data_usage_last_n_days.id
}

resource "anaml_feature" "data_loss_last_30_days" {
  name        = "data_loss_last_30_days"
  description = "Number of incidents where a customers phone failed to retrieve data."
  table       = anaml_table.data_usage.id
  select      = "1"
  filter      = "issue rlike 'data_loss'"
  aggregation = "count"
  days        = 30
}
