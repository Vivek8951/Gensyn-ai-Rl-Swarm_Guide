pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'rl-swarm'
        UPSTREAM_REPO = 'gensyn-ai/rl-swarm'
        DOCKER_REGISTRY = credentials('docker-hub-credentials')
        LAST_BUILD_COMMIT = ''
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    echo "Checked out repository"
                }
            }
        }

        stage('Check Upstream Changes') {
            steps {
                script {
                    def response = sh(
                        script: "curl -s 'https://api.github.com/repos/${UPSTREAM_REPO}/commits/main'",
                        returnStdout: true
                    ).trim()

                    def json = readJSON text: response
                    env.LATEST_COMMIT = json.sha

                    echo "Latest upstream commit: ${env.LATEST_COMMIT}"

                    try {
                        env.LAST_BUILD_COMMIT = readFile('last_build_commit.txt').trim()
                        echo "Last built commit: ${env.LAST_BUILD_COMMIT}"
                    } catch (Exception e) {
                        echo "No previous build found"
                        env.LAST_BUILD_COMMIT = ''
                    }

                    if (env.LATEST_COMMIT != env.LAST_BUILD_COMMIT) {
                        env.SHOULD_BUILD = 'true'
                        echo "Changes detected! Building new image..."
                    } else {
                        env.SHOULD_BUILD = 'false'
                        echo "No changes detected. Skipping build."
                        currentBuild.result = 'SUCCESS'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            when {
                expression { env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    echo "Building Docker image..."
                    sh """
                        docker build -t ${DOCKER_IMAGE_NAME}:latest .
                        docker tag ${DOCKER_IMAGE_NAME}:latest ${DOCKER_REGISTRY_USR}/${DOCKER_IMAGE_NAME}:latest
                        docker tag ${DOCKER_IMAGE_NAME}:latest ${DOCKER_REGISTRY_USR}/${DOCKER_IMAGE_NAME}:\$(date +%Y%m%d)
                    """
                }
            }
        }

        stage('Run Tests') {
            when {
                expression { env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    echo "Running basic image validation..."
                    sh """
                        docker run --rm ${DOCKER_IMAGE_NAME}:latest python3 --version
                        docker run --rm ${DOCKER_IMAGE_NAME}:latest node --version
                        docker run --rm ${DOCKER_IMAGE_NAME}:latest yarn --version
                    """
                }
            }
        }

        stage('Push to Registry') {
            when {
                expression { env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    echo "Pushing to Docker Hub..."
                    sh """
                        echo ${DOCKER_REGISTRY_PSW} | docker login -u ${DOCKER_REGISTRY_USR} --password-stdin
                        docker push ${DOCKER_REGISTRY_USR}/${DOCKER_IMAGE_NAME}:latest
                        docker push ${DOCKER_REGISTRY_USR}/${DOCKER_IMAGE_NAME}:\$(date +%Y%m%d)
                    """
                }
            }
        }

        stage('Update Build Record') {
            when {
                expression { env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    writeFile file: 'last_build_commit.txt', text: env.LATEST_COMMIT
                    echo "Updated last build commit to: ${env.LATEST_COMMIT}"
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    echo "Cleaning up old Docker images..."
                    sh """
                        docker system prune -f || true
                    """
                }
            }
        }
    }

    post {
        success {
            script {
                if (env.SHOULD_BUILD == 'true') {
                    echo "✅ Docker image built and pushed successfully!"
                    echo "Image: ${DOCKER_REGISTRY_USR}/${DOCKER_IMAGE_NAME}:latest"
                    echo "Upstream commit: ${env.LATEST_COMMIT}"
                } else {
                    echo "ℹ️ No changes detected - build skipped"
                }
            }
        }
        failure {
            echo "❌ Build failed! Check logs for details."
        }
        always {
            script {
                sh "docker logout || true"
            }
        }
    }
}
