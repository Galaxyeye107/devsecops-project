pipeline {
    agent any

    // =========================
    // OPTIONS
    // =========================
    options {
        timestamps()
    }

    // =========================
    // ENV
    // =========================
    environment {
        TRIVY_SEVERITY_HIGH = 'HIGH'
        TRIVY_SEVERITY_CRITICAL = 'CRITICAL'
    }

    stages {

        // =========================
        // 1. CHECKOUT
        // =========================
        stage('📥 Checkout Source') {
            steps {
                checkout scm
            }
        }

        // =========================
        // 2. CLEAN
        // =========================
        stage('🧹 Clean Workspace') {
            steps {
                sh '''
                rm -rf gitleaks* tfsec* semgrep* trivy* *.sarif *.json || true
                '''
            }
        }

        // =========================
        // 3. GITLEAKS – SECRET SCAN
        // =========================
        stage('🔐 Secret Scanning (Gitleaks)') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh '''
                    curl -L https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz -o gitleaks.tar.gz
                    tar -xzf gitleaks.tar.gz

                    # ANY secret → CRITICAL → FAIL
                    ./gitleaks detect \
                      --source . \
                      --report-format sarif \
                      --report-path gitleaks.sarif \
                      --exit-code 1
                    '''
                }
            }
        }

        // =========================
        // 4. TFSEC – IaC
        // =========================
        stage('🏗 IaC Security (tfsec)') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    sh '''
                    curl -L https://github.com/aquasecurity/tfsec/releases/download/v1.28.1/tfsec-linux-amd64 -o tfsec
                    chmod +x tfsec

                    # LOW → HIGH → UNSTABLE (tfsec không có exit-code granular)
                    ./tfsec . \
                      --format sarif \
                      --out tfsec.sarif
                    '''
                }
            }
        }

        // =========================
        // 5. SEMGREP – SAST
        // =========================
        stage('🧠 SAST (Semgrep)') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    sh '''
                    pip3 install semgrep --break-system-packages

                    # Any finding (LOW+) → UNSTABLE
                    semgrep scan \
                      --config auto \
                      --sarif \
                      --output semgrep.sarif \
                      --error
                    '''
                }
            }
        }

        // =========================
        // 6. TRIVY – SCA & IMAGE
        // =========================
        stage('📦 Dependency & Image Scan (Trivy)') {
            steps {

                // ---- HIGH → UNSTABLE ----
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    sh '''
                    apt-get update && apt-get install -y docker.io || true

                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
                      sh -s -- -b /usr/local/bin

                    trivy fs . \
                      --severity ${TRIVY_SEVERITY_HIGH} \
                      --exit-code 1 \
                      --format sarif \
                      --output trivy.sarif
                    '''
                }

                // ---- BUILD IMAGE ----
                sh '''
                docker build -t my-app:${BUILD_NUMBER} .
                '''

                // ---- CRITICAL → FAIL ----
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    sh '''
                    trivy image my-app:${BUILD_NUMBER} \
                      --severity ${TRIVY_SEVERITY_CRITICAL} \
                      --exit-code 1
                    '''
                }
            }
        }

        // =========================
        // 7. SECURITY DASHBOARD
        // =========================
        stage('📊 Security Dashboard') {
            steps {
                recordIssues(
                    tools: [
                        sarif(pattern: 'gitleaks.sarif', id: 'gitleaks', name: '🔐 Secrets'),
                        sarif(pattern: 'tfsec.sarif',    id: 'tfsec',    name: '🏗 IaC'),
                        sarif(pattern: 'semgrep.sarif',  id: 'semgrep',  name: '🧠 SAST'),
                        sarif(pattern: 'trivy.sarif',    id: 'trivy',    name: '📦 SCA')
                    ],
                    enabledForFailure: true,
                    skipBlames: true,
                    qualityGates: [
                        [threshold: 0, type: 'TOTAL_CRITICAL'],
                        [threshold: 0, type: 'TOTAL_HIGH', unstable: true]
                    ]
                )

                script {
                    currentBuild.description = '''
🔐 Gitleaks
🏗 tfsec
🧠 Semgrep
📦 Trivy
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
                sh 'echo "✅ Security OK – Terraform can run"'
                // terraform init
                // terraform plan
            }
        }
    }

    // =========================
    // POST
    // =========================
    post {
        always {
            archiveArtifacts artifacts: '*.sarif', fingerprint: true
        }
        unstable {
            echo '⚠️ Có lỗ hổng mức HIGH'
        }
        failure {
            echo '❌ Build FAILED do CRITICAL security issues'
        }
    }
}
