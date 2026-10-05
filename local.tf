locals {
    common_tags = {
        Project = var.project
        Environment = var.environment
        Terraform = "true" 
        Name = local.common_name
    }
    common_name = "${var.project}-${var.environment}" # roboshop-dev
    az_names = slice(data.aws_availability_zones.available.names, 0, 2)
    

}