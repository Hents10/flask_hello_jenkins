pipeline {
    agent {
        kubernetes {
            inheritFrom 'default'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
    - name: python
      image: python:3.11-slim
      command: ["cat"]
      tty: true

    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: ["cat"]
      tty: true

    - name: kubectl
      image: dtzar/helm-kubectl:3.14.2
      command: ["cat"]
      tty: true
"""
        }
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test Python') {
            steps {
                container('python') {
                    sh 'python --version'
                    sh 'pip install -r requirements.txt'
                    sh 'python test.py'
                }
            }
        }

        stage('Build Image') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                    --context $WORKSPACE \
                    --dockerfile $WORKSPACE/Dockerfile \
                    --destination registry.jenkins.svc.cluster.local:5000/pythontest:latest \
                    --insecure --skip-tls-verify
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                container('kubectl') {
                    sh 'kubectl version --client'
                    sh 'kubectl apply -f kubernetes/'
                }
            }
        }
    }

    post {
        always {
            echo "PIPELINE FINISHED"
        }
        success {
            echo "BUILD SUCCESS"
        }
        failure {
            echo "BUILD FAILED"
        }
    }
}
