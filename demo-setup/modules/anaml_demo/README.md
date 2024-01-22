# Anaml Demo Terraform module

This Terraform module creates demo Anaml resources for entities, tables,
features, feature sets, and feature stores, intended to build upon generated
demo data. The module is intended to be suitable for deployment both to local
and remote instances of Anaml, and as such it doesn't include configuration for
clusters, sources, or destinations, which may be expected to vary depending on
where the module is deployed.

The module is imported by the Terraform manifest for GCP as well as by a
separate Terraform manifest for local development.
