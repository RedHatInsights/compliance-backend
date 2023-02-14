pipeline {
    agent {label 'insights' }
    environment {
        APP_NAME="compliance"
        COMPONENT_NAME="compliance"
        IMAGE="quay.io/cloudservices/compliance"

        CICD_URL="https://raw.githubusercontent.com/RedHatInsights/bonfire/master/cicd"
    }
    stages {
        stage('test') {
            steps {
                echo "Hello, World!"
            }
        }
    }
}