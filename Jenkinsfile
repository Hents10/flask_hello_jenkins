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
      command: ["cat"]
      tty: true

    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2
      command:
        - sleep
        - "999999"
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

    - name: kubectl
      image: bitnami/kubectl:latest
      command: ["cat"]
      tty: true

  volumes:
    - name: docker-config
      emptyDir: {}
"""
        }
    }

    environment {
        REGISTRY = "registry.jenkins.svc.cluster.local:5000"
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
  "auths": {
    "${REGISTRY}": {}
  }
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
                        kubectl apply -f kubernetes/deployment.yaml
                        kubectl apply -f kubernetes/service.yaml
                        kubectl rollout status deployment/pythontest --timeout=180s
                    '''
                }
            }
        }

        stage('Verify') {
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
        success { echo 'BUILD SUCCESSFUL' }
        failure { echo 'BUILD FAILED' }
        always { echo 'PIPELINE FINISHED' }
    }
}
