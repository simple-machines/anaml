resource "anaml-operations_user" "genevieve_steele" {
  name       = "Genevieve Steele"
  email      = "genevieve_steele@example.com"
  given_name = "Genevieve"
  surname    = "Steele"
  password   = "hunter23"
  roles      = ["author"]
}

resource "anaml-operations_user" "sonny_bowman" {
  name       = "Sonny Bowman"
  email      = "sonny_bowman@example.com"
  given_name = "Sonny"
  surname    = "Bowman"
  password   = "hunter23"
  roles      = ["author"]
}
