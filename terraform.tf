terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
  cloud { 
    organization = "globo-tfc" 
    
    workspaces { 
      name = "diamonddogs-app-useast1-dev" 
    } 
  } 
}