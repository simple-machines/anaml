resource "anaml_feature_set" "bi_report_std_customer" {
  name        = "bi_report_std_customer"
  description = "These metrics are consumed by the BI system for management reports and charts.\n\n * **Updated Daily**"
  entity      = anaml_entity.customer.id
  features = [
    anaml_feature.bill_percentage_change.id,
    anaml_feature.bill_amount_average.id,
    anaml_feature.plan_size.id,
    anaml_feature.plan_age.id,
    anaml_feature.customer_age.id,
  ]
}

resource "anaml_feature_set" "customer_churn_model_v1" {
  name        = "customer_churn_model_v1"
  description = "Features requireds to train and score a machine learning model predicting likelyhood of customer shopping elsewhere."
  entity = anaml_entity.customer.id
  features = [
    anaml_feature.customer_age.id,
    anaml_feature.items_bought_last_n_days["7"].id,
    anaml_feature.visit_count.id,
    anaml_feature.visted_any_last_14_days.id
  ]
}
