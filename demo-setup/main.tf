terraform {
  required_version = ">= 0.14"
  required_providers {
    # Use fixed versions of Anaml providers so that integration tests are reproducible.
    anaml = {
      source  = "simple-machines/anaml"
      version = ">= 0.0.30"
    }
    anaml-operations = {
      source  = "simple-machines/anaml-operations"
      version = ">= 0.0.30"
    }
  }
}

provider "anaml" {
  host     = var.anaml_api_url
  username = var.anaml_api_apikey
  password = var.anaml_api_secret
  branch   = var.anaml_branch
}

provider "anaml-operations" {
  host     = var.anaml_api_url
  username = var.anaml_api_apikey
  password = var.anaml_api_secret
}

resource "anaml-operations_cluster" "local" {
  name               = "local"
  description        = "A local Spark server cluster for jobs running in docker-compose"
  is_preview_cluster = true

  local {
    anaml_server_url = var.anaml_api_url
    basic {
      username = var.anaml_api_apikey
      password = var.anaml_api_secret
    }
  }
  
  spark_config {
    enable_hive_support = false
    additional_spark_properties = {
      "spark.sql.adaptive.enabled" : "false"
    }
  }
}

resource "anaml-operations_cluster" "spark_docker_preview" {
  name               = "spark_docker_preview"
  description        = "A local Spark server cluster for previews running in docker-compose"
  is_preview_cluster = false

  spark_server {
    spark_server_url = "http://anaml-spark-server:8762"
  }

  spark_config {
    enable_hive_support = false
    additional_spark_properties = {
      # Classpath must be set so that Spark can find the Anaml server
      # dependencies when running Spark jobs. The JAR(s) must be at the provided
      # location on the master and all worker nodes.
      "spark.driver.extraClassPath" : "/opt/docker/lib/*",
      "spark.executor.extraClassPath" : "/opt/docker/lib/*",

      # Reduce the default claims for cores and memory for Spark executors, so
      # we can run more executors for the given resources. Likely not to be
      # optimal for all use cases.
      "spark.dynamicAllocation.maxExecutors" : "1",
      "spark.cores.max" : 1,
      "spark.driver.cores" : 1,
      "spark.executor.cores" : 1,
      "spark.driver.memory" : "512m",
      "spark.executor.memory" : "512m",

      # The Spark documentation recommends 3*N for the number of cores. The defaults are 200.
      "spark.sql.shuffle.partitions" : 3,
      "spark.default.parallelism" : 3,
      "spark.sql.autoBroadcastJoinThreshold" : "-1"
    }
  }
}

resource "anaml-operations_cluster" "spark_docker_job" {
  name               = "spark_docker_job"
  description        = "A local Spark server cluster for jobs running in docker-compose"
  is_preview_cluster = false

  spark_server {
    spark_server_url = "http://anaml-spark-server:8762"
  }

  spark_config {
    enable_hive_support = false
    additional_spark_properties = {
      # Classpath must be set so that Spark can find the Anaml server
      # dependencies when running Spark jobs. The JAR(s) must be at the provided
      # location on the master and all worker nodes.
      "spark.driver.extraClassPath" : "/opt/docker/lib/*",
      "spark.executor.extraClassPath" : "/opt/docker/lib/*",

      # Reduce the default claims for cores and memory for Spark executors, so
      # we can run more executors for the given resources. Likely not to be
      # optimal for all use cases.
      "spark.driver.cores" : 1,
      "spark.executor.cores" : 1,
      "spark.driver.memory" : "512m",
      "spark.executor.memory" : "512m",

      # The Spark documentation recommends 3*N for the number of cores. The defaults are 200.
      "spark.sql.shuffle.partitions" : 3,
      "spark.default.parallelism" : 3,
      "spark.sql.autoBroadcastJoinThreshold" : "-1"
    }
  }
}

resource "anaml-operations_source" "local_orc" {
  name        = "local_orc"
  description = "Local data for testing"

  local {
    path        = "/data/raw"
    file_format = "orc"
  }
}

resource "anaml-operations_source" "local_csv" {
  name        = "local_csv"
  description = "Local data for testing"

  local {
    path        = "/data/raw"
    file_format = "csv"
  }
}

resource "anaml-operations_destination" "local" {
  name        = "local"
  description = "Local data for testing"

  local {
    path        = "/data/outputs"
    file_format = "csv"
  }
}

module "anaml_demo_features" {
  source = "./modules/anaml_demo"
  cluster_id              = anaml-operations_cluster.local.id
  destination_id          = anaml-operations_destination.local.id
  source_id               = anaml-operations_source.local.id
  source_type             = "local_orc"
  destination_type        = "local"
}
