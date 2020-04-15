resource "aws_api_gateway_rest_api" "URLShortener" {
  name        = "URLShortener"
  description = "URL shortener and expander"
}

resource "aws_api_gateway_resource" "URLShortenerResource" {
  rest_api_id = "${aws_api_gateway_rest_api.URLShortener.id}"
  parent_id   = "${aws_api_gateway_rest_api.URLShortener.root_resource_id}"
  path_part   = "test"
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
  rest_api_id          = aws_api_gateway_rest_api.URLShortener.id
  resource_id          = aws_api_gateway_resource.URLShortenerResource.id
  credentials = aws_iam_role.DDBCrudRole.arn
  type                 = "AWS"
  http_method          = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  uri                  = "arn:aws:apigateway:${var.aws_region}:dynamodb:action/GetItem"

  timeout_milliseconds = 29000
}

