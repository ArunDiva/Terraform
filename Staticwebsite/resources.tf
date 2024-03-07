resource "aws_s3_bucket" "arun-static-bucket" {
  bucket = "arun-static-bucket"
}
resource "aws_s3_bucket_public_access_block" "arun-static-bucket" {
  bucket = aws_s3_bucket.arun-static-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "index" {
  bucket = "arun-static-bucket"
  key    = "index.html"
  source = "index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket = "arun-static-bucket"
  key    = "error.html"
  source = "error.html"
  content_type = "text/html"
}


resource "aws_s3_bucket_website_configuration" "arun-static-bucket" {
  bucket = aws_s3_bucket.arun-static-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.arun-static-bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Principal": "*",
      "Resource": "${aws_s3_bucket.arun-static-bucket.arn}/*"
    }
  ]
}
EOF
}