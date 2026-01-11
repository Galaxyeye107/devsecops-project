pipeline {
    agent any

    // =========================
    // GLOBAL OPTIONS
    // =========================
    options {
        timestamps()
    }

    // =========================
    // ENVIRONMENT
    // =========================
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

                # CRITICAL secrets → FAIL pipeline
                ./gitleaks detect \
                  --source . \
                  --report-format sarif \
                  --report-path gitleaks.sarif \
                  --exit-code 1
                '''
            }
        }

        // =========================
        // 4. IAC SECURITY – TFSEC
        // =========================
        stage('🏗 IaC Security (tfsec)') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
                    sh '''
                    curl -L https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64 -o tfsec
                    chmod +x tfsec

                    # Scan ALL severities (LOW → CRITICAL)
                    ./tfsec . --format sarif > tfsec.sarif
                    '''
                }
            }
        }

        // =========================
        // 5. SAST – SEMGREP
        // =========================
        stage('🧠 SAST (Semgrep)') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
                    sh '''
                    pip3 install semgrep --break-system-packages

                    # ERROR rules → UNSTABLE
                    semgrep scan \
                      --config auto \
                      --severity ERROR \
                      --sarif -o semgrep.sarif
                    '''
                }
            }
        }

        // =========================
        // 6. DEPENDENCY & IMAGE SCAN – TRIVY
        // =========================
        stage('📦 Dependency & Image Scan (Trivy)') {
            steps {
                sh '''
                apt-get update && apt-get install -y docker.io || true

                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
                  sh -s -- -b /usr/local/bin

                # FILESYSTEM SCAN (HIGH → UNSTABLE)
                trivy fs \
                  --severity HIGH \
                  --exit-code 0 \
                  --format sarif \
                  -o trivy.sarif .

                # BUILD IMAGE
                docker build -t my-app:${BUILD_NUMBER} .

                # IMAGE SCAN (CRITICAL → FAIL)
                trivy image \
                  --severity CRITICAL \
                  --exit-code 1 \
                  my-app:${BUILD_NUMBER}
                '''
            }
        }

        // =========================
        // 7. SECURITY DASHBOARD
        // =========================
        stage('📊 Security Dashboard') {
            steps {
                recordIssues(
                    tools: [
                        sarif(pattern: 'gitleaks.sarif', id: 'gitleaks', name: '🔐 Secrets (Gitleaks)'),
                        sarif(pattern: 'tfsec.sarif',    id: 'tfsec',    name: '🏗 IaC (tfsec)'),
                        sarif(pattern: 'semgrep.sarif',  id: 'semgrep',  name: '🧠 SAST (Semgrep)'),
                        sarif(pattern: 'trivy.sarif',    id: 'trivy',    name: '📦 SCA / Image (Trivy)')
                    ],
                    enabledForFailure: true,
                    skipBlames: true
                )

                script {
                    currentBuild.description = '''
🔐 Gitleaks – Secrets
🏗 tfsec – Terraform
🧠 Semgrep – SAST
📦 Trivy – Dependencies / Image
                    '''
                }
            }
        }

        // =========================
        // 8. TERRAFORM PLAN
        // =========================
        stage('🚀 Terraform Plan') {
            when {
                expression {
                    currentBuild.result == null || currentBuild.result == 'SUCCESS'
                }
            }
            steps {
                sh 'echo "✅ Security passed – ready for Terraform Plan"'
                // terraform init
                // terraform plan
            }
        }
    }

    // =========================
    // 9. POST ACTIONS
    // =========================
    post {
        always {
            archiveArtifacts artifacts: '*.sarif', fingerprint: true
        }
        unstable {
            echo '⚠️ Build UNSTABLE – có lỗ hổng mức HIGH / ERROR'
        }
        failure {
            echo '❌ Build FAILED do CRITICAL security issues'
        }
    }
}
