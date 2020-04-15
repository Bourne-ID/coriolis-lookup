resource "aws_api_gateway_rest_api" "URLShortener" {
  name        = "URLShortener"
  description = "URL shortener and expander"
}

resource "aws_api_gateway_resource" "URLShortenerResource" {
  rest_api_id = "${aws_api_gateway_rest_api.URLShortener.id}"
  parent_id   = "${aws_api_gateway_rest_api.URLShortener.root_resource_id}"
  path_part   = ""
}

resource "aws_api_gateway_method" "get" {
  rest_api_id   = "${aws_api_gateway_rest_api.URLShortener.id}"
  resource_id   = "${aws_api_gateway_resource.URLShortenerResource.id}"
  http_method   = "GET"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "post" {
  rest_api_id   = "${aws_api_gateway_rest_api.URLShortener.id}"
  resource_id   = "${aws_api_gateway_resource.URLShortenerResource.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "MyDemoIntegration" {
  rest_api_id          = "${aws_api_gateway_rest_api.URLShortener.id}"
  resource_id          = "${aws_api_gateway_resource.URLShortenerResource.id}"
  http_method          = "${aws_api_gateway_method.get.http_method}"
  type                 = "AWS"
  uri                  = "${aws_dynamodb_table.shorturl_lookup.arn}/GET/"

  timeout_milliseconds = 29000

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}