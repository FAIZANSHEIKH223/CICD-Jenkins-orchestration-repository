pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select Terraform environment'
        )
    }

    environment {
        APP_REPO       = 'https://github.com/FAIZANSHEIKH223/practice1.git'
        QUALITY_REPO   = 'https://github.com/FAIZANSHEIKH223/pylint_flake8_int_jenkins.git'
        TERRAFORM_REPO = 'https://github.com/FAIZANSHEIKH223/terraform-aws-infra.git'

        AWS_REGION     = 'us-east-1'

        // GitHub credential used to clone private GitHub repositories
        GITHUB_CREDENTIALS = 'github-creds'

        // SSH private key used to connect Jenkins to Application EC2
        SSH_CREDENTIALS = 'terraform-ec2-ssh'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Checkout Application') {
            steps {
                dir('application') {
                    git branch: 'main',
                        credentialsId: "${GITHUB_CREDENTIALS}",
                        url: "${APP_REPO}"
                }
            }
        }

        stage('Checkout Quality Tools') {
            steps {
                dir('quality-tools') {
                    git branch: 'main',
                        credentialsId: "${GITHUB_CREDENTIALS}",
                        url: "${QUALITY_REPO}"
                }
            }
        }

        stage('Checkout Terraform') {
            steps {
                dir('terraform-infra') {
                    git branch: 'main',
                        credentialsId: "${GITHUB_CREDENTIALS}",
                        url: "${TERRAFORM_REPO}"
                }
            }
        }

        stage('Install Quality Dependencies') {
            steps {
                sh '''
                    set -e

                    python3 -m venv .quality-venv

                    . .quality-venv/bin/activate

                    pip install --upgrade pip

                    pip install -r requirements.txt
                '''
            }
        }

        stage('Run Flake8') {
            steps {
                sh '''
                    set -e

                    . .quality-venv/bin/activate

                    cp quality-tools/.flake8 application/.flake8

                    cd application

                    flake8 .
                '''
            }
        }

        stage('Run Pylint') {
            steps {
                sh '''
                    set -e

                    . .quality-venv/bin/activate

                    cp quality-tools/.pylintrc application/.pylintrc

                    cd application

                    pylint app.py
                '''
            }
        }

        stage('Run Application Tests') {
            steps {
                sh '''
                    set -e

                    . .quality-venv/bin/activate

                    cd application

                    if [ -f test_app.py ]; then
                        pytest -q
                    else
                        echo "No test_app.py found. Skipping pytest."
                    fi
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform-infra') {
                    sh '''
                        terraform init \
                          -input=false \
                          -backend-config=backend-${ENVIRONMENT}.conf
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform-infra') {
                    sh '''
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform-infra') {
                    sh '''
                        terraform plan \
                          -input=false \
                          -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
                          -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform-infra') {
                    sh '''
                        terraform apply \
                          -input=false \
                          -auto-approve \
                          tfplan
                    '''
                }
            }
        }

        stage('Get EC2 IP') {
            steps {
                dir('terraform-infra') {
                    script {
                        env.EC2_PUBLIC_IP = sh(
                            script: 'terraform output -raw ec2_public_ip',
                            returnStdout: true
                        ).trim()

                        echo "Application EC2 IP: ${env.EC2_PUBLIC_IP}"
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sshagent(credentials: ["${SSH_CREDENTIALS}"]) {

                    sh '''
                        set -e

                        echo "Waiting for SSH service..."

                        for i in $(seq 1 30); do
                            if ssh \
                              -o StrictHostKeyChecking=no \
                              -o ConnectTimeout=5 \
                              ubuntu@${EC2_PUBLIC_IP} "echo SSH Ready"; then
                                break
                            fi

                            sleep 10
                        done

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo apt-get update -y && sudo apt-get install -y docker.io"

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo systemctl enable docker && sudo systemctl start docker"

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo docker stop practice1 || true"

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo docker rm practice1 || true"

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo rm -rf /opt/practice1"

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo mkdir -p /opt/practice1"

                        scp \
                          -o StrictHostKeyChecking=no \
                          -r application/* \
                          ubuntu@${EC2_PUBLIC_IP}:/tmp/practice1/

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo mkdir -p /tmp/practice1 && sudo cp -r /tmp/practice1/* /opt/practice1/"

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "cd /opt/practice1 && sudo docker build -t practice1:latest ."

                        ssh \
                          -o StrictHostKeyChecking=no \
                          ubuntu@${EC2_PUBLIC_IP} \
                          "sudo docker run -d \
                           --name practice1 \
                           --restart unless-stopped \
                           -p 8501:8501 \
                           practice1:latest"
                    '''
                }
            }
        }

        stage('Application Health Check') {
            steps {
                sh '''
                    set -e

                    echo "Waiting for application..."

                    sleep 20

                    curl \
                      --fail \
                      --retry 10 \
                      --retry-delay 5 \
                      "http://${EC2_PUBLIC_IP}:8501"
                '''
            }
        }
    }

    post {
        success {
            echo "=========================================="
            echo "CI/CD PIPELINE SUCCESSFUL"
            echo "Application URL:"
            echo "http://${EC2_PUBLIC_IP}:8501"
            echo "=========================================="
        }

        failure {
            echo "=========================================="
            echo "CI/CD PIPELINE FAILED"
            echo "Check the failed stage above."
            echo "=========================================="
        }

        always {
            echo "Pipeline completed."
        }
    }
}
