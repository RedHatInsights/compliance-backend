pipeline {
    agent { label 'rhel8' }
    options {
        timestamps()
    }
    stages {
        stage('no-op') {
            steps {
                sh "echo 'hello world!'"
            }
        }
    }
}

