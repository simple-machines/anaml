resource "random_password" "anaml-postgres-password" {
  length           = 16
  special          = true
  override_special = "_-#"
}

resource "aws_secretsmanager_secret" "anaml-postgres-password-secret" {
  name = "anaml-postgres-password"

  recovery_window_in_days = 0

  tags = {}
}

resource "aws_secretsmanager_secret_version" "anaml-postgres-password-secret-version" {
  secret_id     = aws_secretsmanager_secret.anaml-postgres-password-secret.id
  secret_string = random_password.anaml-postgres-password.result
}

resource "aws_db_subnet_group" "anaml-postgres-subnet-group" {
  name       = "anaml-postgres-subnet-group"
  subnet_ids = module.vpc.private_subnets
  tags = {
    Group = "anaml"
  }
}

resource "aws_security_group" "allow_vpc_ingress_to_postgress" {
  name        = "allow_vpc_ingress_to_postgress"
  description = "Allow nodes within the VPC to connect to RDS Postgres"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "anaml"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_5432_ingress_from_vpc" {
  security_group_id = aws_security_group.allow_vpc_ingress_to_postgress.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_db_instance" "anaml-postgres" {
  identifier_prefix       = "anaml-"
  allocated_storage       = 20
  backup_retention_period = var.db_backup_retention_period
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "15.4"
  instance_class          = "db.m5.large"
  db_name                 = "anaml"
  username                = "anaml"
  password                = random_password.anaml-postgres-password.result
  ca_cert_identifier      = "rds-ca-rsa2048-g1"
  vpc_security_group_ids = [
    aws_security_group.allow_vpc_ingress_to_postgress.id
  ]
  db_subnet_group_name = aws_db_subnet_group.anaml-postgres-subnet-group.name
  skip_final_snapshot  = true
  tags = {
    Group = "anaml"
  }
  kms_key_id = length(var.kms_key_id) > 0 ? var.kms_key_id : null

  storage_encrypted = true

  lifecycle {
    ignore_changes = [engine_version]
  }
}
