pipeline {
    agent any
    stages {
        stage('Checkout Source') {
            steps { checkout scm }
        }

        stage('Secret Scanning (Gitleaks)') {
            steps {
                script {
                    // Tải Gitleaks binary trực tiếp
                    sh 'curl -L https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz -o gitleaks.tar.gz && tar -xzf gitleaks.tar.gz'
                    sh './gitleaks detect --source=. -v || echo "Phát hiện bí mật bị lộ!"'
                }
            }
        }

        stage('Infrastructure Security Scan (tfsec)') {
            steps {
                script {
                    // Tải tfsec binary trực tiếp
                    sh 'curl -L https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64 -o tfsec'
                    sh 'chmod +x tfsec'
                    sh './tfsec .'
                }
            }
        }

        stage('SAST - Application Security Scan (Semgrep)') {
            steps {
                script {
                    // 1. Tải trực tiếp Semgrep binary bản ổn định
                    sh 'curl -L https://github.com/semgrep/semgrep/releases/download/v1.55.0/semgrep-v1.55.0-ubuntu-generic.tar.gz -o semgrep.tar.gz'
                    
                    // 2. Giải nén
                    sh 'tar -xzf semgrep.tar.gz'
                    
                    // 3. Chạy quét (File thực thi nằm trong thư mục vừa giải nén)
                    // Chúng ta dùng --error để bắt lỗi SQL Injection trong app.py
                    sh './semgrep/semgrep scan --config auto --error'
                }
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
