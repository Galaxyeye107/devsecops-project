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
        /*stage('Infrastructure Security Scan') {
            steps {
                Sử dụng Docker để chạy tfsec mà không cần cài đặt tfsec vào Jenkins server
                sh 'docker run --rm -v $(pwd):/src aquasec/tfsec /src'
                Cập nhật lệnh này: Quét trực tiếp thư mục hiện tại (.) 
                và ép buộc trả về lỗi (exit code 1) nếu có vấn đề
                sh 'docker run --rm -v $(pwd):/apps aquasec/tfsec /apps'
                SỬA LẠI DÒNG NÀY: Dùng --workdir để ép tfsec đứng đúng vị trí chứa code
                sh 'docker run --rm -v $(pwd):/src --workdir /src aquasec/tfsec .'
            }
        }*/
        stage('Infrastructure Security Scan') {
            steps {
                script {
                    // 1. Tải tfsec trực tiếp vào thư mục workspace
                    sh 'curl -L -o tfsec https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64'
                    
                    // 2. Cấp quyền thực thi
                    sh 'chmod +x tfsec'
                    
                    // 3. Chạy quét ngay tại chỗ (không dùng qua Docker)
                    sh './tfsec .'
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
