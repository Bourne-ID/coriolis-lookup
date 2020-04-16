resource "aws_api_gateway_rest_api" "URLShortener" {
  name        = "URLShortener"
  description = "URL shortener and expander"
}

resource "aws_api_gateway_resource" "URLShortenerResource" {
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  parent_id   = aws_api_gateway_rest_api.URLShortener.root_resource_id
  path_part   = "{shortCode}"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.URLShortener.id
  resource_id   = aws_api_gateway_resource.URLShortenerResource.id
  http_method   = "GET"
  authorization = "NONE"

}
resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.URLShortener.id
  resource_id   = aws_api_gateway_resource.URLShortenerResource.id
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

  request_templates = {
    "application/json" = <<EOF
{
    "TableName": "${aws_dynamodb_table.shorturl_lookup.name}",
    "Key": {
      "Key": {
        "S": "$input.params('shortCode')"
      }
    }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "successResponse" {
  http_method = "GET"
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "successIntegration" {
  http_method = aws_api_gateway_method_response.successResponse.http_method
  selection_pattern = "200"
  status_code = "200"
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  # Transforms the backend JSON response to XML

}

resource "aws_api_gateway_method_response" "errorResponse" {
  http_method = "GET"
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "400"
}

resource "aws_api_gateway_integration_response" "errorIntegration" {
  http_method = "GET"
  selection_pattern = "400"
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "400"
  # Transforms the backend JSON response to XML

}