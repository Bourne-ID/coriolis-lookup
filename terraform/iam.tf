

resource "aws_iam_policy" "DDBCrudPolicy" {
  name = "DDBCrudPolicy"

  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Resource": [
            "${aws_dynamodb_table.shorturl_lookup.arn}"
          ],
          "Action": [
            "dynamodb:DeleteItem",
            "dynamodb:UpdateItem",
            "dynamodb:GetItem"
          ]
        }
      ]
}
EOF
}

resource "aws_iam_role" "DDBCrudRole" {
  name = "DDBCrudRole"
  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "apigateway.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}

resource "aws_iam_policy" "CloudWatch" {
name = "apiCloudWatch"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "rolePolicyAttachment" {
  policy_arn = aws_iam_policy.CloudWatch.arn
  role = aws_iam_role.DDBCrudRole.name
}


resource "aws_iam_role_policy_attachment" "attachment" {
  policy_arn = aws_iam_policy.DDBCrudPolicy.arn
  role = aws_iam_role.DDBCrudRole.name
}