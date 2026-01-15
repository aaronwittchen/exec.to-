pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-deployer
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    args:
    - "9999999"
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
  - name: kubectl
    image: gcr.io/cloud-builders/kubectl
    command:
    - sleep
    args:
    - "9999999"
  volumes:
  - name: kaniko-secret
    secret:
      secretName: ghcr-kaniko-secret
      items:
      - key: .dockerconfigjson
        path: config.json
'''
        }
    }

    environment {
        REGISTRY = 'ghcr.io'
        IMAGE_NAME = 'aaronwittchen/exec-to'
    }

    triggers {
        pollSCM('H/2 * * * *')  // Check for changes every 2 minutes
    }

    stages {
        stage('Build and Push') {
            steps {
                container('kaniko') {
                    script {
                        env.IMAGE_TAG = env.GIT_COMMIT?.take(7) ?: 'latest'
                        sh """
                            /kaniko/executor \
                                --context=dir://\${WORKSPACE} \
                                --destination=${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} \
                                --destination=${REGISTRY}/${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                container('kubectl') {
                    sh """
                        kubectl set image deployment/exec-to exec-to=${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} -n exec-to
                    """
                }
            }
        }
    }
}
