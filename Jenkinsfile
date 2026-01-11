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
                    // CẬP NHẬT LỆNH CHẠY: Xuất kết quả ra file gitleaks.json
                     // Chúng ta KHÔNG dùng --exit-code 1 ở đây để pipeline vẫn chạy tiếp 
                    // và tổng hợp được báo cáo vào cuối buổi
                    sh './gitleaks detect --source=. --report-format=json --report-path=gitleaks.json || echo "Phát hiện bí mật!"'
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
                    // 1. Cài đặt Docker CLI nhanh chóng nếu container bị mất lệnh
                    sh 'apt-get update && apt-get install -y docker.io || echo "Docker already installed"'

                    // 2. Quét lỗ hổng trong các thư viện (SCA) TRƯỚC khi build
                    // Cách này giúp bạn biết Flask có an toàn không mà không cần lệnh docker
                    sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin'
                    // CẬP NHẬT LỆNH QUÉT:
                    // --exit-code 1: Trả về lỗi nếu tìm thấy lỗ hổng
                    // --severity HIGH,CRITICAL: Chỉ chặn nếu là lỗi nặng
                    sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'

                    // 3. Nếu Docker ổn định, hãy build và quét Image
                    sh 'docker build -t my-app:${BUILD_NUMBER} .'
                    sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL my-app:${BUILD_NUMBER}'
                }
            }
        }
        stage('Security Reports') {
            steps {
                recordIssues(tools: [
                    gitleaks(pattern: 'gitleaks.json', id: 'gitleaks', name: 'Gitleaks Scan'),
                    terraform(pattern: 'tfsec.json', id: 'tfsec', name: 'Terraform Scan'),
                    semgrep(pattern: 'semgrep.json', id: 'semgrep', name: 'Semgrep Scan'),
                    trivy(pattern: 'trivy.json', id: 'trivy', name: 'Container Scan')
                ])
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
