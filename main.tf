# 1. Khai báo vùng hoạt động
provider "aws" {
  region = "ap-southeast-1"
}
# 1. Khai báo khóa KMS (Giải quyết lỗi HIGH về mã hóa) [cite: 81]
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Điểm cộng bảo mật [cite: 82]
}

# 2. Tạo VPC (Mạng ảo riêng biệt) 
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # Cho phép phân giải tên miền trong mạng [cite: 14347]
  enable_dns_hostnames = true # Cấp hostname cho các máy chủ [cite: 14348]

  tags = {
    Name = "secure-vpc"
  }
}
# SỬA LỖI 3: Thêm Flow Logs để giám sát mạng (Yêu cầu MEDIUM)
# Giúp ghi lại mọi luồng traffic để điều tra khi bị tấn công
resource "aws_flow_log" "example" {
  iam_role_arn    = aws_iam_role.app_role.arn
  log_destination = aws_s3_bucket.logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
# 3. Cấu hình S3 LOGS (Sửa lỗi #2 đến #10)
resource "aws_s3_bucket" "logs" {
  bucket = "my-secure-flow-logs-project-30days"
  
  # Chặn xóa nhầm bucket
  force_destroy = false
}
# Bật Logging cho chính nó (Sửa lỗi MEDIUM #2)
resource "aws_s3_bucket_logging" "logs_logging" {
  bucket        = aws_s3_bucket.logs.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
}
# Bật Encryption (Sửa lỗi #4, #7)
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encrypt" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Khóa Public Access (Sửa lỗi #2, #3, #5, #6, #10) - ĐIỂM ĂN TIỀN
resource "aws_s3_bucket_public_access_block" "logs_access" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Bật Versioning (Sửa lỗi #9)
resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}
# 4. Giám sát mạng (Flow Logs)
resource "aws_flow_log" "main_vpc_log" {
  log_destination = aws_s3_bucket.logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
# 3. Tạo Subnet riêng tư (Private Subnet) [cite: 14351]
# Đây là "vùng cấm" để đặt Database, không thể truy cập từ Internet [cite: 2211]
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private-subnet"
  }
}

# 4. Tạo Tường lửa (Security Group) [cite: 14616]
resource "aws_security_group" "web_sg" {
  name        = "web-application-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow HTTPS only"

  # Chỉ cho phép HTTPS (cổng 443) đi vào [cite: 14708]
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # tfsec:ignore:aws-ec2-no-public-ingress-sgr (Chấp nhận rủi ro cho Web Public)
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Luôn cho phép server đi ra Internet để cập nhật bản vá bảo mật [cite: 15926]
  egress {
    description = "Allow outbound to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # tfsec:ignore:aws-ec2-no-public-egress-sgr (Cho phép server tải bản vá bảo mật)
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Tạo Quyền truy cập tối thiểu (IAM Role(Least Privilege)) [cite: 210, 15391]
resource "aws_iam_role" "app_role" {
  name = "application-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
# 1. Tạo khóa KMS riêng để mã hóa bí mật (Sửa lỗi Result #1)
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key cho Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true # Tự động xoay vòng khóa mỗi năm (Security Best Practice) [cite: 10179, 11811]
}
resource "aws_secretsmanager_secret" "db_password" {
  name        = "prod/db/password-${random_string.suffix.result}"
  description = "Mật khẩu quản trị cho Database RDS"
  # Điểm DevSecOps: Gắn tag để quản lý chi phí và quyền hạn [cite: 748, 2002]
  # Gắn key_id vào để mã hóa bí mật bằng KMS Key riêng
  kms_key_id  = aws_kms_key.secrets_key.arn
  tags = {
    Environment = "production"
  }
}
# Khai báo máy tạo chuỗi ngẫu nhiên để tránh trùng tên tài nguyên cần cho đoạn random ở trên dòng 128
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
resource "aws_secretsmanager_secret_version" "db_password_val" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "MySuperSecurePassword123!" # Tạm thời để demo, sau này ta sẽ dùng biến động [cite: 496, 1895]
}
resource "aws_iam_policy" "secrets_policy" {
  name        = "AllowReadDBSecret"
  description = "Cho phép ứng dụng đọc mật khẩu từ Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.db_password.arn # Chỉ cho phép truy cập đúng 1 tài nguyên này [cite: 146, 205, 9665]
      },
    ]
  })
}

# Gắn policy này vào Role của server bạn đã tạo ở bài trước
resource "aws_iam_role_policy_attachment" "app_role_secrets" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}
# =========================
# ❌ INTENTIONALLY INSECURE EC2 (FOR TFSEC TEST)
# Mục đích: tạo 1 lỗi HIGH để test Security Dashboard
# =========================
resource "aws_instance" "tfsec_high_demo" {
  ami           = "ami-0df7a207adb9748c7" # Amazon Linux 2 (Singapore)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private.id
  iam_instance_profile = aws_iam_instance_profile.app_profile.name

  # ❌ LỖI HIGH: EBS root volume KHÔNG mã hóa
  root_block_device {
    encrypted = false
  }

  tags = {
    Name = "tfsec-high-demo"
  }
}
