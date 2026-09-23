pipeline {
    agent any

    environment {
        DEV_IMAGE  = 'sund123/dev'
        PROD_IMAGE = 'sund123/prod'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DEV_IMAGE}:${BUILD_NUMBER} ."
            }
        }

        stage('Docker Hub Login & Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

                        if [ "$BRANCH_NAME" = "dev" ]; then
                            echo "Pushing DEV image..."

                            docker push ${DEV_IMAGE}:${BUILD_NUMBER}

                            docker tag ${DEV_IMAGE}:${BUILD_NUMBER} ${DEV_IMAGE}:latest
                            docker push ${DEV_IMAGE}:latest

                        elif [ "$BRANCH_NAME" = "master" ]; then
                            echo "Pushing PROD image..."

                            docker tag ${DEV_IMAGE}:${BUILD_NUMBER} ${PROD_IMAGE}:${BUILD_NUMBER}
                            docker push ${PROD_IMAGE}:${BUILD_NUMBER}

                            docker tag ${DEV_IMAGE}:${BUILD_NUMBER} ${PROD_IMAGE}:latest
                            docker push ${PROD_IMAGE}:latest
                        fi
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            when {
                branch 'master'
            }

            steps {
                echo 'Deploying production application...'
                sh 'chmod +x deploy.sh && ./deploy.sh'
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
    }
}