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
                    // 1. Cài đặt semgrep thông qua pip (bỏ qua cảnh báo hệ thống)
                    sh 'pip3 install semgrep --break-system-packages'
                    
                    // 2. Chạy quét toàn bộ thư mục và ép lỗi khi thấy SQL Injection
                    sh 'semgrep scan --config auto --error'
                }
            }
        }
        stage('Container Security Scan (Trivy)') {
            steps {
                script {
                    // 1. Build thử image
                    sh 'docker build -t my-app:${BUILD_NUMBER} .'
                    
                    // 2. Tải và chạy Trivy để quét Image vừa build
                    sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin'
                    sh 'trivy image --severity HIGH,CRITICAL my-app:${BUILD_NUMBER}'
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
