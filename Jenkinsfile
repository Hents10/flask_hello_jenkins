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
  serviceAccountName: default

  containers:

    - name: python
      image: python:3.11-slim
      command:
        - cat
      tty: true

    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command:
        - /busybox/cat
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

    - name: kubectl
      image: rancher/kubectl:v1.29.0
      command:
        - sleep
      args:
        - "999999"
      tty: true

  volumes:
    - name: docker-config
      emptyDir: {}
"""
        }
    }

    environment {
        IMAGE_NAME = "registry.jenkins.svc.cluster.local:5000/pythontest:latest"
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

        stage('Prepare Kaniko Auth') {
            steps {
                container('kaniko') {
                    sh '''
                        mkdir -p /kaniko/.docker

                        cat > /kaniko/.docker/config.json <<EOF
{
  "insecure-registries" : [
    "registry.jenkins.svc.cluster.local:5000"
  ]
}
EOF
                    '''
                }
            }
        }

        stage('Build image (Kaniko)') {
            steps {
                container('kaniko') {
                    sh '''
                        /kaniko/executor \
                          --context $WORKSPACE \
                          --dockerfile $WORKSPACE/Dockerfile \
                          --destination=$IMAGE_NAME \
                          --insecure \
                          --skip-tls-verify \
                          --verbosity=info
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl version --client

                        kubectl delete deployment flask-app --ignore-not-found=true

                        kubectl create deployment flask-app \
                          --image=$IMAGE_NAME

                        kubectl expose deployment flask-app \
                          --type=NodePort \
                          --port=5000 \
                          --target-port=5000 \
                          --ignore-not-found=true
                    '''
                }
            }
        }

        stage('Verify') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl get pods
                        kubectl get svc
                        kubectl get deployment
                    '''
                }
            }
        }
    }

    post {

        always {
            echo 'PIPELINE FINISHED'
        }

        success {
            echo 'BUILD SUCCESS'
        }

        failure {
            echo 'BUILD FAILED'
        }
    }
}
