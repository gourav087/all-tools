pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo 'GitHub code downloaded successfully'
            }
        }

        stage('Terraform Init and Validate') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'terraform-tfvars',
                        variable: 'TFVARS_FILE'
                    )
                ]) {
                    sh '''
                        cp "$TFVARS_FILE" terraform/terraform.tfvars

                        cd terraform

                        terraform init
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Get Application IP') {
            steps {
                script {
                    env.APP_PRIVATE_IP = sh(
                        script: 'cd terraform && terraform output -raw private_ip',
                        returnStdout: true
                    ).trim()

                    env.APP_PUBLIC_IP = sh(
                        script: 'cd terraform && terraform output -raw public_ip',
                        returnStdout: true
                    ).trim()
                }

                echo "Application Private IP: ${APP_PRIVATE_IP}"
                echo "Application Public IP: ${APP_PUBLIC_IP}"
            }
        }

        stage('Ansible Deployment') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'app-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        chmod 600 "$SSH_KEY"

                        ansible-playbook \
                          -i "${APP_PRIVATE_IP}," \
                          -u "$SSH_USER" \
                          --private-key "$SSH_KEY" \
                          --ssh-common-args='-o StrictHostKeyChecking=no' \
                          ansible/deploy.yml
                    '''
                }
            }
        }

        stage('Verify Website') {
            steps {
                sh '''
                    curl --retry 12 \
                         --retry-delay 5 \
                         --retry-connrefused \
                         -fsS \
                         "http://${APP_PUBLIC_IP}/"

                    echo ""
                    echo "Website deployment successful!"
                '''
            }
        }
    }

    post {
        success {
            echo 'All DevOps stages completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check Console Output.'
        }
    }
}
