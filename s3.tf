
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "portfolio" {
  bucket = "rahul-portfolio-${data.aws_caller_identity.current.account_id}-ap-south-1"
}

resource "aws_s3_bucket_website_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  depends_on = [
    aws_s3_bucket_public_access_block.portfolio
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadForWebsite"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.portfolio.arn}/*"
    }]
  })
}

resource "aws_s3_object" "portfolio_files" {
  for_each = fileset("${path.module}/portfolio-site", "**")

  bucket = aws_s3_bucket.portfolio.id
  key    = each.value
  source = "${path.module}/portfolio-site/${each.value}"
  etag   = filemd5("${path.module}/portfolio-site/${each.value}")

  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    webp = "image/webp"
    pdf  = "application/pdf"
    txt  = "text/plain"
  }, lower(element(reverse(split(".", each.value)), 0)), "application/octet-stream")
}

output "s3_website_url" {
  value = "http://${aws_s3_bucket_website_configuration.portfolio.website_endpoint}"
}
