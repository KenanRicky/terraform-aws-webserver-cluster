# live/dev/services/webserver-cluster/main.tf
module "webserver_cluster" {
  source = "github.com/KenanRicky/terraform-aws-webserver-cluster?ref=v0.0.1"

  cluster_name  = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
}