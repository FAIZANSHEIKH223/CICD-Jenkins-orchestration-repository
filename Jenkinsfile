pipeline {

    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            description: 'Terraform environment'
        )
    }

    environment {

        APP_REPO = 'https://github.com/FAIZANSHEIKH223/practice1.git'

        QUALITY_REPO = 'https://github.com/FAIZANSHEIKH223/pylint_flake8_int_jenkins.git'

        TERRAFORM_REPO = 'https://github.com/FAIZANSHEIKH223/terraform-aws-infra.git'

        APP_DIR = 'practice1'

        QUALITY_DIR = 'quality-tools'

        TERRAFORM_DIR = 'terraform-infra'

        AWS_DEFAULT_REGION = 'us-east-1'

        APP_PORT = '8501'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout Application') {
            steps {
                sh """
                    git clone ${APP_REPO} ${APP_DIR}
                """
            }
        }

        stage('Checkout Quality Tools') {
            steps {
                sh """
                    git clone ${QUALITY_REPO} ${QUALITY_DIR}
                """
            }
        }

        stage('Install Dependencies') {
            steps {
                sh """
                    python3 -m venv .venv

                    . .venv/bin/activate

                    pip install --upgrade pip

                    if [ -f ${APP_DIR}/requirements.txt ]; then
                        pip install -r ${APP_DIR}/requirements.txt
                    fi

                    pip install -r ${QUALITY_DIR}/requirements-quality.txt
                """
            }
        }

        stage('Flake8') {
            steps {
                sh """
                    . .venv/bin/activate

                    chmod +x ${QUALITY_DIR}/scripts/run_flake8.sh

                    ${QUALITY_DIR}/scripts/run_flake8.sh ${APP_DIR}
                """
            }
        }

        stage('Pylint') {
            steps {
                sh """
                    . .venv/bin/activate

                    chmod +x ${QUALITY_DIR}/scripts/run_pylint.sh

                    ${QUALITY_DIR}/scripts/run_pylint.sh ${APP_DIR}
                """
            }
        }

        stage('Checkout Terraform') {
            steps {
                sh """
                    git clone ${TERRAFORM_REPO} ${TERRAFORM_DIR}
                """
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh """
                        terraform plan \
                        -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
                        -out=tfplan
                    """
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Get EC2 IP') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    script {
                        env.EC2_PUBLIC_IP = sh(
                            script: 'terraform output -raw ec2_public_ip',
                            returnStdout: true
                        ).trim()

                        echo "EC2 IP: ${env.EC2_PUBLIC_IP}"
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sshagent(credentials: ['terraform-ec2-ssh']) {

                    sh """
                        chmod +x scripts/deploy.sh

                        ./scripts/deploy.sh \
                        "${EC2_PUBLIC_IP}"
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    chmod +x scripts/health_check.sh

                    ./scripts/health_check.sh \
                    "${EC2_PUBLIC_IP}"
                """
            }
        }
    }

    post {

        success {
            echo """
            ========================================
            PIPELINE SUCCESS
            ========================================

            Application URL:
            http://${EC2_PUBLIC_IP}:8501
            """
        }

        failure {
            echo "PIPELINE FAILED"
        }
    }
}
