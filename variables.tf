variable "vpc_cidr" {
  type = string
  validation {
    condition = endswith(var.vpc_cidr,"/16")
    error_message = " for vpc address space"
  }
}
variable "subnet" {
  type=map(object({
    cidr=string
    az=string
  }))
}
variable "imageID" {
  type=string
}
variable "instance_type" {
  type = string
}
variable "keypair" {
  type = string
}
variable "public_key" {
  type=string
}
variable "script_file" {
  type = string
}
variable "desired_capacity" {
  type=number
  default = 1
}
variable "minimum_capacity" {
  type=number
  default = 1
}
variable "maximum_capacity" {
  type=number
  default = 2
}
variable "scaling-adjustment" {
  type = number
  default = 1
}
variable "cooldown" {
  type=number
  default = 300
}