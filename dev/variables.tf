variable "server_port" {
    type = number
    default = 80
    description = "webserver port"
}

variable "my_ip" {
    description = "My public IP"
    type = string
    default = "0.0.0.0/0"
}