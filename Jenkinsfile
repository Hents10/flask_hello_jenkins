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

    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command:
        - /busybox/sh
      args:
        - -c
        - "cat"
      tty: true

      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

    - name: kubectl
      image: bitnami/kubectl:latest
      command:
        - /bin/sh
      args:
        - -c
        - "cat"
      tty: true

  volumes:
    - name: docker-config
      emptyDir: {}

    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        REGISTRY   = "registry.jenkins.svc.cluster.local:5000"
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
  "insecure-registries": [
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
                          --context=$WORKSPACE \
                          --dockerfile=$WORKSPACE/Dockerfile \
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
                        echo "KUBECTL VERSION"
                        kubectl version --client=true

                        echo "DEPLOYMENT"

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
                        echo "PODS"
                        kubectl get pods -o wide

                        echo "SERVICES"
                        kubectl get svc

                        echo "DEPLOYMENTS"
                        kubectl get deployments
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
