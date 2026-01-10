pipeline {
    agent any
    
    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }
        stage('Secret Scanning') {
            steps {
                // Sử dụng Gitleaks để tìm các bí mật bị lộ trong lịch sử commit
                sh 'docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest detect --source="/path" -v'
            }
        }        
        stage('Infrastructure Security Scan') {
            steps {
                // Sử dụng Docker để chạy tfsec mà không cần cài đặt tfsec vào Jenkins server
                sh 'docker run --rm -v $(pwd):/src aquasec/tfsec /src'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                // Chỉ chạy Plan nếu bước Scan ở trên thành công
                sh 'echo "Hạ tầng an toàn, bắt đầu tạo bản kế hoạch triển khai..."'
                // sh 'terraform init && terraform plan' (Nếu bạn đã setup AWS Credentials)
            }
        }
    }
}
