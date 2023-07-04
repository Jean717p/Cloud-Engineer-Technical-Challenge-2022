# local state backend for mockup scope. #UPDATE: Found out that s3 is in free tier
# terraform {
#   backend "local" {
#     path = "./state/terraform.tfstate"
#   }
# }

# Define Terraform backend using a S3 bucket for storing the Terraform state and dynamodb table for tf lock
terraform {
  backend "s3" {
    bucket = "my-bucket"
    key    = "terraform"
    encrypt = true
    profile = "myprofile"
    dynamodb_table = "mylocktable"
    region = "us-east-2"
  }
}
