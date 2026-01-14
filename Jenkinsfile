pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
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

    stages {
        stage('Build and Push') {
            steps {
                container('kaniko') {
                    script {
                        def imageTag = env.GIT_COMMIT?.take(7) ?: 'latest'
                        sh """
                            /kaniko/executor \
                                --context=dir://\${WORKSPACE} \
                                --destination=${REGISTRY}/${IMAGE_NAME}:${imageTag} \
                                --destination=${REGISTRY}/${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }
    }
}
