pipeline {

    agent any

    environment {

        APP_REPO = 'https://github.com/FAIZANSHEIKH223/practice1.git'

        QUALITY_REPO = 'https://github.com/FAIZANSHEIKH223/pylint_flake8_int_jenkins.git'

        TERRAFORM_REPO = 'https://github.com/FAIZANSHEIKH223/terraform-aws-infra.git'

        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {

        stage('Checkout Application') {
            steps {
                sh '''
                    git clone ${APP_REPO} practice1
                '''
            }
        }

        stage('Checkout Quality Tools') {
            steps {
                sh '''
                    git clone ${QUALITY_REPO} quality-tools
                '''
            }
        }

        stage('Run Flake8') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate

                    pip install --upgrade pip
                    pip install -r quality-tools/requirements-quality.txt

                    chmod +x quality-tools/scripts/run_flake8.sh

                    quality-tools/scripts/run_flake8.sh practice1
                '''
            }
        }

        stage('Run Pylint') {
            steps {
                sh '''
                    . .venv/bin/activate

                    chmod +x quality-tools/scripts/run_pylint.sh

                    quality-tools/scripts/run_pylint.sh practice1
                '''
            }
        }

        stage('Checkout Terraform') {
            steps {
                sh '''
                    git clone ${TERRAFORM_REPO} terraform-infra
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform-infra') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform-infra') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform-infra') {
                    sh '''
                        terraform plan \
                        -var-file="environments/dev/terraform.tfvars" \
                        -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform-infra') {
                    sh '''
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Get Infrastructure Information') {
            steps {
                dir('terraform-infra') {
                    script {

                        env.EC2_PUBLIC_IP = sh(
                            script: 'terraform output -raw ec2_public_ip',
                            returnStdout: true
                        ).trim()

                        echo "EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    chmod +x scripts/deploy.sh

                    ./scripts/deploy.sh \
                    "${EC2_PUBLIC_IP}"
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    chmod +x scripts/health_check.sh

                    ./scripts/health_check.sh \
                    "${EC2_PUBLIC_IP}"
                '''
            }
        }
    }
}
