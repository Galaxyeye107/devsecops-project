pipeline {
    agent any

    // =========================
    // TÙY CHỌN CHUNG CHO PIPELINE
    // =========================
    options {
        timestamps()                // Hiển thị timestamp cho mỗi log       
    }
    // =========================
    // BIẾN MÔI TRƯỜNG DÙNG CHUNG
    // =========================
    environment {
        TRIVY_SEVERITY = 'HIGH,CRITICAL'   // Chỉ quan tâm lỗi nặng
    }

    stages {

        // =========================
        // 1. LẤY SOURCE CODE
        // =========================
        stage('📥 Checkout Source') {
            steps {
                // Clone source code từ Git repository
                checkout scm
            }
        }

        // =========================
        // 2. LÀM SẠCH WORKSPACE
        // =========================
        stage('🧹 Clean Workspace') {
            steps {
                // Xóa toàn bộ file scan cũ để tránh nhiễu báo cáo
                sh '''
                rm -rf gitleaks* tfsec* semgrep* trivy* *.json *.sarif || true
                '''
            }
        }

        // =========================
        // 3. SECRET SCANNING - GITLEAKS
        // =========================
        stage('🔐 Secret Scanning (Gitleaks)') {
            steps {
                // 1. Tải Gitleaks binary trực tiếp (không cần cài system-wide)
                // 2. Quét toàn bộ source code
                // 3. Xuất báo cáo theo chuẩn SARIF để Jenkins đọc được
                // 4. Không fail pipeline tại đây (|| true)
                sh '''
                curl -L https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz -o gitleaks.tar.gz
                tar -xzf gitleaks.tar.gz
                ./gitleaks detect \
                  --source . \
                  --report-format sarif \
                  --report-path gitleaks.sarif || true
                '''
            }
        }

        // =========================
        // 4. IAC SECURITY - TFSEC
        // =========================
        stage('🏗 Infrastructure Security (tfsec)') {
            steps {
                // 1. Tải tfsec binary
                // 2. Quét toàn bộ file Terraform
                // 3. Xuất kết quả SARIF để hiển thị dashboard
                sh '''
                curl -L https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64 -o tfsec
                chmod +x tfsec
                ./tfsec . --format sarif > tfsec.sarif || true
                '''
            }
        }

        // =========================
        // 5. SAST - SEMGREP
        // =========================
        stage('🧠 SAST (Semgrep)') {
            steps {
                // 1. Cài Semgrep bằng pip
                // 2. Quét code theo rule auto
                // 3. Xuất SARIF cho Jenkins
                sh '''
                pip3 install semgrep --break-system-packages
                semgrep scan --config auto --sarif -o semgrep.sarif || true
                '''
            }
        }

        // =========================
        // 6. DEPENDENCY & CONTAINER SCAN - TRIVY
        // =========================
        stage('📦 Dependency & Container Scan (Trivy)') {
            steps {
                // 1. Cài Docker nếu agent chưa có
                // 2. Cài Trivy
                // 3. Quét thư viện (SCA) trước khi build image
                // 4. Build Docker image
                // 5. Quét image với severity HIGH, CRITICAL
                sh '''
                apt-get update && apt-get install -y docker.io || true

                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
                  sh -s -- -b /usr/local/bin

                trivy fs \
                  --format sarif \
                  --severity ${TRIVY_SEVERITY} \
                  -o trivy.sarif . || true

                docker build -t my-app:${BUILD_NUMBER} .
                trivy image \
                  --severity ${TRIVY_SEVERITY} \
                  --exit-code 1 my-app:${BUILD_NUMBER} || true
                '''
            }
        }

        // =========================
        // 7. SECURITY DASHBOARD (TRUNG TÂM)
        // =========================
        stage('📊 Security Dashboard') {
            steps {
                // 1. Thu thập toàn bộ file SARIF
                // 2. Gom tất cả tool vào 1 dashboard
                // 3. Hiển thị severity, trend, số lượng issue
                // 4. Áp quality gate cho lỗi mới
                recordIssues(
                    tools: [
                        sarif(pattern: 'gitleaks.sarif', id: 'gitleaks', name: '🔐 Secrets (Gitleaks)'),
                        sarif(pattern: 'semgrep.sarif', id: 'semgrep', name: '🧠 SAST (Semgrep)'),
                        sarif(pattern: 'tfsec.sarif', id: 'tfsec', name: '🏗 IaC (tfsec)'),
                        sarif(pattern: 'trivy.sarif', id: 'trivy', name: '📦 Dependencies (Trivy)')
                    ],
                    enabledForFailure: true,
                    skipBlames: true,
                    qualityGates: [
                        // Có bất kỳ CRITICAL nào → FAIL
                        [threshold: 0, type: 'TOTAL_CRITICAL'],

                        // Có HIGH → UNSTABLE
                        [threshold: 0, type: 'TOTAL_HIGH', unstable: true]
                    ]
                )

                // Ghi chú ngắn gọn ngay tại build
                script {
                    currentBuild.description = '''
                    🔐 Gitleaks
                    🧠 Semgrep
                    🏗 tfsec
                    📦 Trivy
                    '''
                }
            }
        }

        // =========================
        // 8. TERRAFORM PLAN (CHỈ CHẠY KHI AN TOÀN)
        // =========================
        stage('🚀 Terraform Plan') {
            when {
                // Chỉ chạy khi pipeline không FAIL
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh 'echo "Hạ tầng an toàn – sẵn sàng triển khai 🚀"'
                // terraform init && terraform plan
            }
        }
    }

    // =========================
    // 9. HẬU XỬ LÝ PIPELINE
    // =========================
    post {
        always {
            // Lưu lại toàn bộ báo cáo để audit / download
            archiveArtifacts artifacts: '*.sarif', fingerprint: true
        }
        unstable {
            echo '⚠️ Có security issues mức HIGH'
        }
        failure {
            echo '❌ Build failed do phát hiện lỗ hổng CRITICAL'
        }
    }
}
