variable "app_name" {
  description = "Name of the app"
  type        = string
  default = "analytics"
}

variable "image" {
  description = "Container image for deployment"
  type        = string
  default = 
}

variable "port" {
  description = "Container port exposed"
  type        = number
}
