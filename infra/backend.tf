terraform {
  backend "s3" {
    bucket = "tf-state-lab1" # Bucket onde o estado será salvo
    key    = "lab1/terraform.tfstate" # Caminho do arquivo de estado dentro do bucket
    region = "us-east-2"
  }
}
