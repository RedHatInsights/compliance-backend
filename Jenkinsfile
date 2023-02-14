pipeline {
    agent {label 'insights' }
    environment {
        APP_NAME="compliance"
        COMPONENT_NAME="compliance"
        IMAGE="quay.io/cloudservices/compliance"
        export IQE_PLUGINS="compliance"
        export IQE_MARKER_EXPRESSION="compliance_smoke"
        export IQE_FILTER_EXPRESSION=""
        export IQE_CJI_TIMEOUT="30m" # 30 minutes
        export REF_ENV="insights-stage"
        export COMPONENTS_W_RESOURCES="compliance"

        CICD_URL="https://raw.githubusercontent.com/RedHatInsights/bonfire/master/cicd"
    }
    stages {
        stage('Install bonfire repo/initialize') {
            steps {
                sh ```
                    curl -s $CICD_URL/bootstrap.sh > .cicd_bootstrap.sh && source .cicd_bootstrap.sh
                ```
            }
        }

        stage('Build the PR commit image') {
            steps {
                sh ```
                    source "${APP_ROOT}/build_deploy.sh"

                    // Make directory for artifacts
                    mkdir -p artifacts
                ```
            }
        }

        stage('run-parallel-branches') {
            parallel (
                stage('Run unit tests') {
                    steps {
                        sh ```
                            source "${APP_ROOT}/build_deploy.sh"
                        ```
                    }
                }
                stage('Run smoke tests') {
                    steps {
                        sh ```
                            // shellcheck source=/dev/null
                            source "${CICD_ROOT}/deploy_ephemeral_env.sh"
                            // shellcheck source=/dev/null
                            source "${CICD_ROOT}/cji_smoke_test.sh"
                            // shellcheck source=/dev/null
                            source "${CICD_ROOT}/post_test_results.sh"
                        ```
                    }
                }
            )
        }
    }
}
