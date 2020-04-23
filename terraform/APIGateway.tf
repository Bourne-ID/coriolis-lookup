resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.DDBCrudRole.arn
}

resource "aws_api_gateway_rest_api" "URLShortener" {
  name        = "URLShortener"
  description = "URL shortener and expander"

}

resource "aws_api_gateway_resource" "URLShortenerResource" {
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  parent_id   = aws_api_gateway_rest_api.URLShortener.root_resource_id
  path_part   = "{shortCode}"
}

resource "aws_api_gateway_method" "lookupMethod" {
  rest_api_id   = aws_api_gateway_rest_api.URLShortener.id
  resource_id   = aws_api_gateway_resource.URLShortenerResource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "callIntoDynamo" {
  rest_api_id          = aws_api_gateway_rest_api.URLShortener.id
  resource_id          = aws_api_gateway_resource.URLShortenerResource.id
  credentials = aws_iam_role.DDBCrudRole.arn
  type                 = "AWS"
  http_method          = aws_api_gateway_method.lookupMethod.http_method
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
  http_method = aws_api_gateway_method.lookupMethod.http_method
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "307"

}

resource "aws_api_gateway_integration_response" "successIntegration" {
  depends_on = [aws_api_gateway_integration.callIntoDynamo]
  http_method = aws_api_gateway_method.lookupMethod.http_method
  status_code = aws_api_gateway_method_response.successResponse.status_code
  resource_id = aws_api_gateway_resource.URLShortenerResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  selection_pattern = "200"

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
  depends_on = [aws_api_gateway_integration.callIntoDynamo]
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

##Root
resource "aws_api_gateway_method" "rootMethod" {
  authorization = "NONE"
  http_method = "GET"
  resource_id = aws_api_gateway_rest_api.URLShortener.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
}

resource "aws_api_gateway_integration" "rootIntegration" {
  http_method = aws_api_gateway_method.rootMethod.http_method
  resource_id = aws_api_gateway_rest_api.URLShortener.root_resource_id
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

resource "aws_api_gateway_integration_response" "rootIntegrationResponse" {
  depends_on = [aws_api_gateway_integration.rootIntegration]
  http_method = aws_api_gateway_method.rootMethod.http_method
  resource_id = aws_api_gateway_rest_api.URLShortener.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "200"
  selection_pattern = "200"
  response_parameters = {
    "method.response.header.Content-Type" = "'text/html'"
  }
  response_templates = {
    "text/html" = local.noMatchTempalte
  }
}

resource "aws_api_gateway_method_response" "rootMethodResponse" {
  http_method = aws_api_gateway_method.rootMethod.http_method
  resource_id = aws_api_gateway_rest_api.URLShortener.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = false
  }
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

resource "aws_api_gateway_method_settings" "noMatchSettings" {
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  stage_name  = aws_api_gateway_deployment.primaryDeployment.stage_name
  method_path = "${aws_api_gateway_resource.NoMatchResource.path_part}/${aws_api_gateway_method.noMatchMethod.http_method}"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
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

locals {
  noMatchTempalte = file("website/missing.html")
}
resource "aws_api_gateway_integration_response" "noMatchIntegrationResponse" {
  depends_on = [aws_api_gateway_integration.callIntoDynamo]
  http_method = aws_api_gateway_method.noMatchMethod.http_method
  resource_id = aws_api_gateway_resource.NoMatchResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "200"
  selection_pattern = "200"
  response_parameters = {
    "method.response.header.Content-Type" = "'text/html'"
  }
  response_templates = {
    "text/html" = local.noMatchTempalte
  }
}

resource "aws_api_gateway_method_response" "noMatchMethodResponse" {
  http_method = aws_api_gateway_method.noMatchMethod.http_method
  resource_id = aws_api_gateway_resource.NoMatchResource.id
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
  status_code = "200"
  response_parameters = {
    "method.response.header.Content-Type" = false
  }
}

resource "aws_api_gateway_deployment" "primaryDeployment" {
  depends_on = [
    aws_api_gateway_integration.callIntoDynamo,
    aws_api_gateway_integration.noMatchIntegration,
    aws_api_gateway_integration.rootIntegration,
    aws_api_gateway_method.lookupMethod,
    aws_api_gateway_method.noMatchMethod,
    aws_api_gateway_method.rootMethod,
  aws_api_gateway_method_response.errorResponse,
  aws_api_gateway_method_response.noMatchMethodResponse,
  aws_api_gateway_method_response.successResponse,
    aws_api_gateway_method_response.rootMethodResponse
  ]

  stage_name = "primary"
  rest_api_id = aws_api_gateway_rest_api.URLShortener.id
}

resource "aws_api_gateway_domain_name" "dns" {
  domain_name = var.domain
  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id = aws_api_gateway_rest_api.URLShortener.id
  domain_name = aws_api_gateway_domain_name.dns.domain_name
  stage_name = aws_api_gateway_deployment.primaryDeployment.stage_name
}

output "URL" {
  value = aws_api_gateway_deployment.primaryDeployment.invoke_url
}