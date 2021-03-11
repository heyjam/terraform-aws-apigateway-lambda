locals {
  zipfile = var.lambda_zip_filename == "" ? "temp.zip" : "${var.lambda_zip_filename}.zip"
  
}