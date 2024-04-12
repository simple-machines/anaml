resource "anaml_table" "towns" {
  name        = "towns"
  description = <<-EOT
  Reference data on regions and postcodes.

  * Sourced from Expedia, imported weekly.
  EOT
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "towns" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "towns" : null
  }

  event {
    entities = {
      (anaml_entity.town.id) = "town"
    }
    timestamp_column = "cast(concat_ws('-', year, month, day) as date)"
  }
}

resource "anaml_table" "towers" {
  name        = "towers"
  description = "Cell towers identified by a `tower_id`."
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "towers" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "towers" : null
  }
  event {
    entities = {
      (anaml_entity.tower.id) = "tower"
    }
    timestamp_column = "cast(concat_ws('-', year, month, day) as date)"
  }
}

resource "anaml_table" "plans" {
  name        = "plans"
  description = "Information about phone plans"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "plan" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "plan" : null
  }
  event {
    entities = {
      (anaml_entity.phone_plan.id) = "plan"
      (anaml_entity.customer.id)   = "customer"
    }
    timestamp_column = "start_date"
  }
}

resource "anaml_table" "customer" {
  name        = "customers"
  description = "Customer demographic information"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "customers" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "customers" : null
  }
  event {
    entities = {
      (anaml_entity.customer.id) = "customer"
    }
    timestamp_column = "join_date"
  }
}

resource "anaml_table" "data_usage" {
  name        = "data_usage"
  description = "Plan data usage"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "data_usage" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "data-usage" : null
  }
  event {
    entities = {
      (anaml_entity.phone_plan.id) = "plan"
    }
    timestamp_column = "usage_time"
  }
}

resource "anaml_table" "bills" {
  name        = "bills"
  description = "Plan billing usage"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "bills" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "bills" : null
  }
  event {
    entities = {
      (anaml_entity.customer.id)   = "customer"
      (anaml_entity.phone_plan.id) = "plan"
    }
    timestamp_column = "end_billing_period"
  }
}

resource "anaml_table" "transactions" {
  name        = "transactions"
  description = "Supermarket transactions"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "transactions" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "transactions" : null
  }
  event {
    entities = {
      (anaml_entity.customer.id) = "customer"
      (anaml_entity.store.id)    = "store"
    }
    timestamp_column = "time"
  }
}


resource "anaml_table" "sku" {
  name        = "sku"
  description = "SKU information"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "sku" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "sku" : null
  }
}

resource "anaml_table" "sku_hierarchy" {
  name        = "sku_hierarchy"
  description = "SKU Hierarchy information"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "sku_hierarchy" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "sku-hierarchy" : null
  }
}


resource "anaml_table" "brands" {
  name        = "brands"
  description = "Brand information"
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "brands" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "brands" : null
  }
}

resource "anaml_table" "labels" {
  name        = "labels"
  description = "Actual Customer information for use as labels in model prediction."
  source {
    source     = var.source_id
    table_name = var.source_type == "hive" || var.source_type == "snowflake" ? "labels" : null
    folder     = contains(["local", "gcs", "s3a"], var.source_type) ? "labels" : null
  }
}

resource "anaml_table" "sku_enriched" {
  name        = "sku_enriched"
  description = "Enriched sku"
  sources = [
    anaml_table.sku.id
    , anaml_table.sku_hierarchy.id
  ]

  expression = <<-EOT
    select sku,
      cost as sku_cost,
      brand,
      s.hierarchy_leaf,
      sh.leaf.description as sku_description,
      sh.parent,
      shp.leaf.description as parent_description
    from sku s
    inner join sku_hierarchy sh on s.hierarchy_leaf = sh.leaf.leaf
    inner join sku_hierarchy shp on sh.parent = shp.leaf.leaf
  EOT
}

resource "anaml_table" "transactions_enriched" {
  name        = "transactions_enriched"
  description = "Enriched transactions"
  sources = [
    anaml_table.transactions.id
    , anaml_table.sku_enriched.id
    , anaml_table.brands.id
  ]

  event {
    entities = {
      (anaml_entity.customer.id) = "customer"
      (anaml_entity.store.id)    = "store"
    }
    timestamp_column = "time"
  }

  expression = <<-EOT
    SELECT
      transactions.*,
      sku_enriched.sku_cost,
      sku_enriched.hierarchy_leaf,
      sku_enriched.sku_description,
      sku_enriched.parent,
      sku_enriched.parent_description,
      brands.name,
      brands.socio_economic
    FROM
      transactions
    JOIN
      sku_enriched
    ON
      transactions.sku = sku_enriched.sku
    JOIN
      brands
    ON
      sku_enriched.brand = brands.brand
  EOT
}
