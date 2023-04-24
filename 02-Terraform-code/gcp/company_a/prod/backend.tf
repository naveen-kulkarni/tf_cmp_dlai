terraform {
  backend "gcs" {
      bucket = "naveen-s3"
      prefix = "terraform/statefile"
      credentials = "my-project-14538-384315-32db0c5b35a6.json"
}
}