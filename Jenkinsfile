pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent-my-app'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    component: ci

spec:
  containers:

  - name: python
    image: python:3.11
    command: ["cat"]
    tty: true

  - name: docker
    image: docker:24-cli
    command: ["cat"]
    tty: true
    volumeMounts:
      - mountPath: /var/run/docker.sock
        name: docker-sock

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true

  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
"""
        }
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {

        stage('Start') {
            steps {
                echo 'PIPELINE START'
            }
        }

        stage('Test python') {
            steps {
                container('python') {
                    echo 'TEST PYTHON START'

                    sh 'pip install -r requirements.txt'
                    sh 'python test.py'

                    echo 'TEST PYTHON END'
                }
            }
        }

        stage('Build image') {
            steps {
                container('docker') {
                    echo 'BUILD IMAGE START'

                    sh 'docker version'

                    sh 'docker build -t localhost:4000/pythontest:latest .'
                    sh 'docker push localhost:4000/pythontest:latest'

                    echo 'BUILD IMAGE END'
                }
            }
        }

        stage('Deploy') {
            steps {
                container('kubectl') {
                    echo 'DEPLOY START'

                    sh 'kubectl version --client'

                    sh 'kubectl apply -f kubernetes/deployment.yaml'
                    sh 'kubectl apply -f kubernetes/service.yaml'

                    sh 'kubectl rollout status deployment/pythontest || true'

                    echo 'DEPLOY END'
                }
            }
        }

        stage('End') {
            steps {
                echo 'PIPELINE SUCCESS'
            }
        }
    }

    post {
        success {
            echo 'BUILD SUCCESSFUL'
        }
        failure {
            echo 'BUILD FAILED'
        }
    }
}
