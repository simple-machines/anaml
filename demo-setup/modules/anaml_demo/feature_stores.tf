resource "anaml-operations_feature_store" "bi_report_std_customer" {
  name        = "bi_report_std_customer"
  description = "These metrics are consumed by the BI system for management reports and charts.\n\n * **Updated Daily**"
  enabled     = true
  feature_set = anaml_feature_set.bi_report_std_customer.id
  cluster     = var.cluster_id

  dynamic "destination" {
    for_each = var.destination_type == "bigquery" || var.destination_type == "snowflake" ? [1] : []
    content {
      destination = var.destination_id
      table {
        name = "bi_report_std_customer"
      }
    }
  }

  dynamic "destination" {
    for_each = var.destination_type == "local" || var.destination_type == "gcs" ? [1] : []
    content {
      destination = var.destination_id
      folder {
        path                 = "bi_report_std_customer"
        partitioning_enabled = true
        save_mode            = "overwrite"
      }
    }
  }

  daily_schedule {
    start_time_of_day = "02:00:00"
  }
}

resource "anaml-operations_feature_store" "customer_churn_model_v1" {
  name        = "customer_churn_model_v1"
  description = "Features requireds to train and score a machine learning model predicting likelyhood of customer leaving the service."
  enabled     = true
  feature_set = anaml_feature_set.customer_churn_model_v1.id
  cluster     = var.cluster_id

  dynamic "destination" {
    for_each = var.destination_type == "bigquery" || var.destination_type == "snowflake" ? [1] : []
    content {
      destination = var.destination_id
      table {
        name = "customer_churn_model_v1"
      }
    }
  }

  dynamic "destination" {
    for_each = var.destination_type == "local" || var.destination_type == "gcs" ? [1] : []
    content {
      destination = var.destination_id
      folder {
        path                 = "customer_churn_model_v1"
        partitioning_enabled = true
        save_mode            = "overwrite"
      }
    }
  }

  daily_schedule {
    start_time_of_day = "02:20:00"
  }
}
