variable "api_key" {
type = string
description = "API Key Id from Intersight"
}
variable "secretkey" {
type = string
description = "The path to your secretkey file for Intersight"
}
variable "api_endpoint" {
/*type = string
description = "The Intersight end point"*/
default = "https://www.intersight.com"
}
variable "cluster_name" {
type = string
}
variable "s3_key" {
  type = string
}
variable "s3_key_id" {
  type = string
}
