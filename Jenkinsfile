pipeline {
  agent any

  environment {
    // keep the same credentials id you use in Jenkins
    DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
  }

  options {
    // keep build logs a bit cleaner and allow ANSI if needed
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        // ensure checkout happens on an agent so FilePath is available
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh '''
          echo "Building project..."
          # add your build commands here, e.g. mvn, pip install, make, etc.
        '''
      }
    }

    stage('Test') {
      steps {
        sh '''
          echo "Running tests..."
          # run test commands here
        '''
      }
    }

    stage('Docker: Build & Push') {
      when {
        expression { return env.DOCKERHUB_CREDENTIALS != null }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "Building docker image..."
            # docker build -t myimage:latest .
            echo "Logging into Docker Hub..."
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            # docker tag myimage:latest $DOCKER_USER/myimage:latest
            # docker push $DOCKER_USER/myimage:latest
          '''
        }
      }
    }
  }

  post {
    always {
      // runs on the agent (because agent any is declared) so hudson.FilePath is present
      echo 'Running post/always cleanup'
      sh 'echo cleanup actions (e.g., rm -rf build artifacts)'
    }
    success {
      echo 'Build succeeded'
    }
    failure {
      echo 'Build failed'
    }
  }
}
