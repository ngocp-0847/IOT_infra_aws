# Setup GitHub Actions cho Lambda Deployment

## Tổng quan

Module CI/CD đã được cập nhật để sử dụng GitHub Actions thay vì CodePipeline để deploy Lambda functions. Module này tạo:

- IAM role với OIDC provider cho GitHub Actions
- Các quyền cần thiết để deploy Lambda functions
- Secure authentication không cần AWS credentials

## Cấu trúc mới

### Resources được tạo:
- `aws_iam_openid_connect_provider.github`: OIDC provider cho GitHub
- `aws_iam_role.github_actions`: IAM role cho GitHub Actions
- `aws_iam_role_policy.github_actions_policy`: Policy với quyền deploy Lambda

### Outputs:
- `github_actions_role_arn`: ARN của IAM role để sử dụng trong GitHub Actions
- `github_actions_role_name`: Tên của IAM role
- `github_oidc_provider_arn`: ARN của OIDC provider

## Cách setup GitHub Actions

### 1. Deploy infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 2. Lấy ARN của IAM role
```bash
terraform output -json | jq '.cicd_github_actions_role_arn.value'
```

### 3. Cấu hình GitHub Repository

#### Thêm Secrets:
- `AWS_ROLE_ARN`: ARN của IAM role từ output trên

#### Thêm Variables:
- `PROJECT_NAME`: Tên project (ví dụ: `iot-platform`)
- `ENVIRONMENT`: Environment (ví dụ: `dev` hoặc `prod`)
- `AWS_REGION`: AWS region (ví dụ: `us-east-1`)

### 4. Workflow file

File `.github/workflows/deploy-lambda.yml` đã được tạo với cấu hình cơ bản. Workflow này:

- Trigger khi có push vào branch `main` và thay đổi trong `modules/lambda/lambda/`
- Sử dụng OIDC để authenticate với AWS
- Build ZIP packages từ Python source code
- Deploy Lambda functions bằng `aws lambda update-function-code`
- Test functions sau khi deploy

### 5. Permissions

IAM role được cấp các quyền sau:
- **Lambda**: Update function code, configuration, aliases, versions
- **CloudWatch Logs**: Tạo và ghi logs
- **IAM**: PassRole cho Lambda execution roles

**Lưu ý**: Không cần ECR permissions vì Lambda functions sử dụng ZIP deployment.

## Bảo mật

- Sử dụng OIDC thay vì long-lived access keys
- Chỉ cho phép repository cụ thể assume role
- Permissions được giới hạn theo principle of least privilege
- GitHub thumbprints được cập nhật theo khuyến nghị của AWS

## Migration từ CodePipeline

### Đã loại bỏ:
- CodePipeline và CodeBuild resources
- S3 artifact bucket (không cần thiết cho GitHub Actions)
- CodeStar connection
- ECR repositories (chuyển từ container images sang ZIP deployment)
- Các variables không sử dụng: `github_branch`, `terraform_workdir`, `buildspec_override`, `*_image_tag`

### Lợi ích của GitHub Actions + ZIP deployment:
- Tích hợp tốt hơn với GitHub
- Không tốn phí AWS services (CodePipeline, CodeBuild, ECR)
- Deploy nhanh hơn với ZIP files
- Linh hoạt hơn trong cấu hình workflow
- Parallel jobs và matrix builds
- Ecosystem rộng lớn của GitHub Actions
- Dễ debug và troubleshoot hơn

## Troubleshooting

### Lỗi "AssumeRoleWithWebIdentity failed"
- Kiểm tra ARN của IAM role trong GitHub Secrets
- Đảm bảo repository name khớp với condition trong IAM role
- Verify GitHub OIDC provider thumbprints

### Lambda deployment failed
- Kiểm tra function name format: `{project_name}-{function_name}-{environment}`
- Đảm bảo Lambda functions đã tồn tại (được tạo bởi Terraform)
- Check CloudWatch Logs để debug chi tiết

### Permission denied
- Verify IAM policy có đủ quyền cho resources cần thiết
- Check resource ARN patterns trong policy
