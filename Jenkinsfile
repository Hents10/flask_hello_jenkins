pipeline {

    agent {
        kubernetes {

            inheritFrom 'default'

            yaml """
apiVersion: v1
kind: Pod

metadata:
  labels:
    component: ci

spec:

  serviceAccountName: jenkins

  containers:

    - name: python
      image: python:3.11-slim
      command:
        - cat
      tty: true

    - name: docker
      image: docker:24-cli
      command:
        - cat
      tty: true
      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock

    - name: kubectl
      image: bitnami/kubectl:latest
      command:
        - cat
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

    environment {
        IMAGE_NAME = "host.minikube.internal:4000/pythontest:latest"
    }

    stages {

        stage('Start') {
            steps {
                echo 'PIPELINE START'
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test python') {
            steps {

                container('python') {

                    echo 'TEST PYTHON START'

                    sh '''
                        python --version
                        pip install --no-cache-dir -r requirements.txt
                        python test.py
                    '''

                    echo 'TEST PYTHON END'
                }
            }
        }

        stage('Build image') {
            steps {

                container('docker') {

                    echo 'BUILD IMAGE START'

                    sh '''
                        docker version

                        docker build -t ${IMAGE_NAME} .

                        docker images

                        docker push ${IMAGE_NAME}
                    '''

                    echo 'BUILD IMAGE END'
                }
            }
        }

        stage('Deploy') {
            steps {

                container('kubectl') {

                    echo 'DEPLOY START'

                    sh '''
                        kubectl version --client

                        kubectl apply -f kubernetes/deployment.yaml

                        kubectl apply -f kubernetes/service.yaml

                        kubectl rollout status deployment/pythontest --timeout=120s
                    '''

                    echo 'DEPLOY END'
                }
            }
        }

        stage('Verify Deployment') {
            steps {

                container('kubectl') {

                    echo 'VERIFY DEPLOYMENT START'

                    sh '''
                        kubectl get pods
                        kubectl get svc
                    '''

                    echo 'VERIFY DEPLOYMENT END'
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

        always {
            echo 'PIPELINE FINISHED'
        }
    }
}
