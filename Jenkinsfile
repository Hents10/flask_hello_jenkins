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
      image: docker:27.0.3-cli
      command:
        - cat
      tty: true

      env:
        - name: DOCKER_API_VERSION
          value: "1.44"

      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock

        - name: docker-config
          mountPath: /root/.docker

  volumes:

    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock

    - name: docker-config
      emptyDir: {}
"""
        }
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
                    sh '''
                        python --version
                        pip install --no-cache-dir -r requirements.txt
                        python test.py
                    '''
                }
            }
        }

        stage('Build image') {
            steps {
                container('docker') {

                    sh '''
                        echo "CONFIGURING DOCKER INSECURE REGISTRY"

                        mkdir -p /root/.docker

                        cat > /root/.docker/config.json <<EOF
{
  "insecure-registries": ["host.minikube.internal:4000"]
}
EOF

                        echo "CHECK DOCKER"
                        docker version

                        echo "BUILD IMAGE"
                        docker build -t ${IMAGE_NAME} .

                        echo "PUSH IMAGE"
                        docker push ${IMAGE_NAME}

                        docker images
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl version --client
                        kubectl apply -f kubernetes/deployment.yaml
                        kubectl apply -f kubernetes/service.yaml
                        kubectl rollout status deployment/pythontest --timeout=180s
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl get pods -o wide
                        kubectl get svc
                    '''
                }
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
