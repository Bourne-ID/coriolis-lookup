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
  http_method = aws_api_gateway_method.get.http_method
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "301"
}

resource "aws_api_gateway_integration_response" "successIntegration" {
  http_method = aws_api_gateway_method_response.successResponse.http_method
  status_code = aws_api_gateway_method_response.successResponse.status_code
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id

  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
#if($inputRoot.toString().contains("Item"))
#set($context.responseOverride.header.Location = $inputRoot.Item.URL.S)
#else
#set($context.responseOverride.header.Location = "/noMatch")
#end
EOF
  }
}

resource "aws_api_gateway_method_response" "errorResponse" {
  http_method = "GET"
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "400"
}

resource "aws_api_gateway_integration_response" "errorIntegration" {
  http_method = aws_api_gateway_method_response.errorResponse.http_method
  selection_pattern = "400"
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "400"
  # Transforms the backend JSON response to XML

}


## No match page
resource "aws_api_gateway_resource" "NoMatchResource" {
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  parent_id   = aws_api_gateway_rest_api.URLShortener.root_resource_id
  path_part   = "noMatch"
}

resource "aws_api_gateway_method" "noMatchMethod" {
  authorization = "NONE"
  http_method = "GET"
  resource_id = aws_api_gateway_resource.NoMatchResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
}

resource "aws_api_gateway_integration" "noMatchIntegration" {
  http_method = aws_api_gateway_method.noMatchMethod.http_method
  resource_id = aws_api_gateway_resource.NoMatchResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  type = "MOCK"

  request_templates = {
    "application/json" = <<EOF
{
"statusCode": 200
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "noMatchIntegrationResponse" {
  http_method = aws_api_gateway_method.noMatchMethod.http_method
  resource_id = aws_api_gateway_resource.NoMatchResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "200"
  selection_pattern = "200"

  response_templates = {
    "application/json" = <<EOF
{
"statusCode": 200,
"message": "Hello from API Gateway!"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "noMatchMethodResponse" {
  http_method = aws_api_gateway_method.noMatchMethod.http_method
  resource_id = aws_api_gateway_resource.NoMatchResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "200"
}

resource "aws_api_gateway_deployment" "MyDemoDeployment" {
  depends_on = [
    aws_api_gateway_integration.MyDemoIntegration,
    aws_api_gateway_integration.noMatchIntegration]

  stage_name = "primary"
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
}

resource "aws_api_gateway_domain_name" "dns" {
  domain_name = var.domain
  regional_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

output "URL" {
  value = aws_api_gateway_deployment.MyDemoDeployment.invoke_url
}