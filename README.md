# DevOps CI/CD Orchestration

This repository contains the centralized Jenkins pipeline and deployment
scripts used to orchestrate the application CI/CD process.

The repository is responsible for:

- Fetching application source code
- Running automated tests
- Building Docker images
- Pushing Docker images to Amazon ECR
- Deploying applications to Amazon EC2
- Configuring Docker logging
- Performing application health checks

---

# Architecture

The overall flow is:

Developer
    |
    | git push
    v
GitHub Application Repository
    |
    v
Jenkins
    |
    +--> Checkout Application
    |
    +--> Run Tests
    |
    +--> Build Docker Image
    |
    +--> Push Image to Amazon ECR
    |
    v
Target EC2
    |
    +--> Pull Docker Image
    |
    +--> Stop Old Container
    |
    +--> Start New Container
    |
    v
Health Check

---

# Repository Structure

```text
devops-cicd/
│
├── Jenkinsfile
│
├── scripts/
│   ├── deploy.sh
│   ├── setup_ec2.sh
│   ├── configure_logging.sh
│   └── health_check.sh
│
└── README.md
