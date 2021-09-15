
terraform {
  required_providers {
    intersight = {
      source = "CiscoDevNet/intersight"
      version = ">=1.0.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "intersight" {
  apikey    = var.api_key
  secretkey = var.secretkey
  endpoint = "https://intersight.com"
}

data "intersight_kubernetes_cluster" "my-cluster" {
    name = var.cluster_name
}

locals {
    kube_config = yamldecode(base64decode(data.intersight_kubernetes_cluster.my-cluster.results[0].kube_config))
}

provider "kubernetes" {
  host = local.kube_config.clusters[0].cluster.server
  client_certificate = base64decode(local.kube_config.users[0].user.client-certificate-data)
  client_key = base64decode(local.kube_config.users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
}

provider "kubectl" {
  host = local.kube_config.clusters[0].cluster.server
  client_certificate = base64decode(local.kube_config.users[0].user.client-certificate-data)
  client_key = base64decode(local.kube_config.users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
  load_config_file = false
}

data "kubectl_file_documents" "eck_operator_manifests" {
    content = file("./eck-operator.yaml")
}

resource "kubectl_manifest" "eck_operator" {
    count     = length(data.kubectl_file_documents.eck_operator_manifests.documents)
    yaml_body = element(data.kubectl_file_documents.eck_operator_manifests.documents, count.index)
}

resource "kubernetes_namespace" "elastic_ns" {
  metadata {
    name = "elastic"
  }
}

data "kubectl_file_documents" "elasticsearch_manifests" {
  content = templatefile("./elasticsearch-manifest.yaml", { s3_key = "${var.s3_key}", s3_key_id = "${var.s3_key_id}" })
}

resource "kubectl_manifest" "elasticsearch" {
    count     = length(data.kubectl_file_documents.elasticsearch_manifests.documents)
    yaml_body = element(data.kubectl_file_documents.elasticsearch_manifests.documents, count.index)
}

data "kubectl_file_documents" "kibana_manifests" {
    content = file("./kibana-manifest.yaml")
}

resource "kubectl_manifest" "kibana" {
    count     = length(data.kubectl_file_documents.kibana_manifests.documents)
    yaml_body = element(data.kubectl_file_documents.kibana_manifests.documents, count.index)
}

