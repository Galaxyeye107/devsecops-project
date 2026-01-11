pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        TRIVY_SEVERITY = 'HIGH,CRITICAL'
    }

    stages {

        // =========================
        // 1. CHECKOUT SOURCE
        // =========================
        stage('📥 Checkout Source') {
            steps {
                checkout scm
            }
        }

        // =========================
        // 2. CLEAN WORKSPACE
        // =========================
        stage('🧹 Clean Workspace') {
            steps {
                sh '''
                rm -rf gitleaks* tfsec* semgrep* trivy* *.sarif *.json || true
                '''
            }
        }

        // =========================
        // 3. SECRET SCANNING – GITLEAKS
        // =========================
        stage('🔐 Secret Scanning (Gitleaks)') {
            steps {
                sh '''
                curl -L https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz -o gitleaks.tar.gz
                tar -xzf gitleaks.tar.gz

                # KHÔNG FAIL – chỉ tạo report
                ./gitleaks detect \
                  --source . \
                  --config .gitleaks.toml \
                  --no-git \
                  --report-format sarif \
                  --report-path gitleaks.sarif || true
                '''
            }
        }

        // =========================
        // 4. IAC SECURITY – TFSEC (OK)
        // =========================
        stage('🏗 IaC Security (tfsec)') {
            steps {
                sh '''
                curl -L https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64 -o tfsec
                chmod +x tfsec

                ./tfsec . --format sarif > tfsec.sarif || true
                '''
            }
        }

        // =========================
        // 5. SAST – SEMGREP
        // =========================
        stage('🧠 SAST (Semgrep)') {
            steps {
                sh '''
                pip3 install semgrep --break-system-packages || true

                # KHÔNG FAIL – lấy toàn bộ severity
                semgrep scan \
                  --config auto \
                  --sarif -o semgrep.sarif || true
                '''
            }
        }

        // =========================
        // 6. DEPENDENCY / IMAGE SCAN – TRIVY (OK)
        // =========================
        stage('📦 Dependency & Image Scan (Trivy)') {
            steps {
                sh '''
                apt-get update && apt-get install -y docker.io || true

                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
                  sh -s -- -b /usr/local/bin

                # FILESYSTEM SCAN (KHÔNG FAIL)
                trivy fs \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 \
                  --skip-dirs .git,node_modules,.terraform,.venv,target,dist \
                  --format sarif \
                  -o trivy.sarif .

                # BUILD IMAGE
                docker build -t my-app:${BUILD_NUMBER} .

                # IMAGE SCAN (KHÔNG FAIL)
                trivy image \
                  --severity CRITICAL \
                  --exit-code 0 \
                  my-app:${BUILD_NUMBER}
                '''
            }
        }

        // =========================
        // 7. SECURITY DASHBOARD (QUAN TRỌNG)
        // =========================
        stage('📊 Security Dashboard') {
    steps {
        recordIssues(
            tools: [
                sarif(pattern: 'gitleaks.sarif', id: 'gitleaks', name: '🔐 Secrets (Gitleaks)'),
                sarif(pattern: 'tfsec.sarif',    id: 'tfsec',    name: '🏗 IaC (tfsec)'),
                sarif(pattern: 'semgrep.sarif',  id: 'semgrep',  name: '🧠 SAST (Semgrep)'),
                sarif(pattern: 'trivy.sarif',    id: 'trivy',    name: '📦 Dependencies (Trivy)')
            ],
            enabledForFailure: true,
            skipBlames: true,

            // =========================
            // QUALITY GATES (CHUẨN)
            // =========================
            qualityGates: [
                // Có BẤT KỲ issue nào → UNSTABLE
                [threshold: 1, type: 'TOTAL', unstable: true],

                // Trên 5 issues → FAIL
                [threshold: 5, type: 'TOTAL']
            ]
        )

        script {
            currentBuild.description = '''
🔐 Gitleaks – Secrets
🏗 tfsec – Terraform
🧠 Semgrep – SAST
📦 Trivy – SCA / Image
            '''
        }
    }
}


        // =========================
        // 8. TERRAFORM PLAN (KHÔNG BỊ SKIP)
        // =========================
        stage('🚀 Terraform Plan') {
            steps {
                sh 'echo "🚀 Terraform Plan (Security results already collected)"'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*.sarif', fingerprint: true
        }
        success {
            echo '✅ Pipeline chạy hoàn tất – kiểm tra Security Dashboard'
        }
    }
}
