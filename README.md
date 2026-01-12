# 🛡️ End-to-End DevSecOps Automation Pipeline

A production-ready CI/CD pipeline featuring automated multi-layer security gates for Python applications on AWS.

## 📝 Project Overview
Dự án này thực hiện tự động hóa quy trình bảo mật (Shift-Left Security) cho toàn bộ chu kỳ phát triển ứng dụng (SDLC). Hệ thống không chỉ kiểm tra code mà còn quét hạ tầng (IaC) và container image để đảm bảo không có lỗ hổng nào lọt vào môi trường Production.



## 🏗️ System Architecture
1. **Infrastructure:** AWS resources (VPC, EC2, IAM, S3) được quản lý bởi **Terraform**.
2. **CI/CD:** **Jenkins** thực hiện orchestrate toàn bộ luồng công việc.
3. **Security Standards:** Áp dụng chuẩn **SARIF** để tổng hợp báo cáo bảo mật tập trung.

## 🛡️ Integrated Security Gates
Dự án tích hợp 4 lớp bảo mật tự động:

* **Secret Scanning (Gitleaks):** Phát hiện các nhạy cảm như AWS Keys, Passwords bị lộ trong Git history.
* **Infrastructure as Code Scan (tfsec):** Kiểm tra lỗi cấu hình AWS Security Groups, IAM Policies sai quy cách.
* **Static Application Security Testing - SAST (Semgrep):** Truy tìm lỗ hổng mã nguồn như SQL Injection, XSS.
* **Software Composition Analysis - SCA & Image Scan (Trivy):** Quét lỗ hổng trong các thư viện (requirements.txt) và các lớp Docker Image.

## 💡 Key Technical Implementations
* **Multi-stage Docker Build:** Tối ưu hóa Dockerfile để giảm bề mặt tấn công (Attack Surface) và giảm 60% kích thước image.
* **Non-root User Execution:** Cấu hình container chạy dưới quyền user hạn chế để ngăn chặn leo thang đặc quyền.
* **Automated Security Dashboard:** Sử dụng Plugin **Warnings Next Generation** để trực quan hóa lỗ hổng qua biểu đồ xu hướng.
* **Standardized Reporting:** Xuất kết quả dưới định dạng **SARIF**, cho phép quản trị tập trung nhiều công cụ quét khác nhau.



## 🚀 How to Use
1. **Prerequisites:**
    * AWS Account & IAM User with programmatic access.
    * Jenkins Server with Docker and Terraform installed.
    * Warnings Next Generation Plugin installed on Jenkins.

2. **Setup Pipeline:**
    * Create a new Pipeline Job in Jenkins.
    * Link your GitHub repository.
    * Add AWS Credentials to Jenkins Credentials Store.
    * Build!

## 📈 Future Roadmap
* [ ] Integrate **AWS Secrets Manager** for dynamic secret rotation.
* [ ] Deploy to **Kubernetes (EKS)** using Helm Charts.
* [ ] Add **DAST (OWASP ZAP)** for runtime vulnerability scanning.

---
**Author:** PHAN THANH TRUNG
**Email:** galaxyeye74@gmail.com
