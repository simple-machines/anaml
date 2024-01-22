resource "anaml_entity" "town" {
  name           = "town"
  description    = "A town"
  default_column = "town_name"
}

resource "anaml_entity" "tower" {
  name           = "tower"
  description    = "A cell tower"
  default_column = "tower"
}

resource "anaml_entity" "customer" {
  name           = "customer"
  description    = "A customer identified in the system"
  default_column = "customer"
}

resource "anaml_entity" "phone_plan" {
  name           = "phone_plan"
  description    = "A phone plan"
  default_column = "plan"
}

resource "anaml_entity" "household" {
  name           = "household"
  description    = "A household level view"
  default_column = "household"
}

resource "anaml_entity" "store" {
  name           = "store"
  description    = "A retail outlet"
  default_column = "store"
}
