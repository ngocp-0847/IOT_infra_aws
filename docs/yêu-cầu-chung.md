Các Yêu cầu Chung (Áp dụng cho TẤT CẢ các đề bài)
Bất kể bạn chọn đề bài nào, giải pháp của bạn phải đáp ứng tất cả các yêu cầu cốt lõi sau đây:
Infrastructure as Code (IaC):
Toàn bộ hạ tầng phải được định nghĩa 100% bằng code (Tự do lựa chọn giữa Terraform, Pulumi, hoặc AWS CDK).
Mã nguồn IaC phải được lưu trữ trong một kho chứa Git.
Bảo mật là trên hết (Security First):
Thiết kế VPC: Phải có public và private subnets. Các thành phần nhạy cảm (database, cache, worker) phải nằm trong private subnets.
Quyền tối thiểu (Least Privilege): Tất cả các IAM Roles (cho EC2, Lambda, ECS Task, EKS Pod) chỉ được cấp những quyền thực sự cần thiết để hoạt động.
Quản lý Bí mật: Nghiêm cấm hardcode bất kỳ thông tin nhạy cảm nào. Phải sử dụng AWS Secrets Manager hoặc Parameter Store.
CI/CD Toàn diện:
Thiết lập một pipeline GitHub Actions hoàn chỉnh.
Pipeline phải tự động build, test, quét lỗ hổng bảo mật (ví dụ: Trivy), và triển khai lên AWS.
Giám sát & Quan sát (Monitoring & Observability):
Phải thiết lập giám sát cho các chỉ số quan trọng của hệ thống (hạ tầng và ứng dụng).
Tập trung hóa log vào CloudWatch Logs hoặc một hệ thống tương đương.
Thiết lập ít nhất một cảnh báo (Alarm) quan trọng cho dịch vụ.
Tài liệu hóa:
Cung cấp một file README.md chuyên nghiệp, bao gồm:
Một sơ đồ kiến trúc hệ thống.
Giải thích các lựa chọn thiết kế quan trọng.