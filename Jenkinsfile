def secrets = [
    [path: params.VAULT_PATH_SVC_ACCOUNT_EPHEMERAL, engineVersion: 1, secretValues: [
        [envVar: 'OC_LOGIN_TOKEN', vaultKey: 'oc-login-token'],
        [envVar: 'OC_LOGIN_SERVER', vaultKey: 'oc-login-server']]],
    [path: params.VAULT_PATH_QUAY_PUSH, engineVersion: 1, secretValues: [
        [envVar: 'QUAY_USER', vaultKey: 'user'],
        [envVar: 'QUAY_TOKEN', vaultKey: 'token']]],
    [path: params.VAULT_PATH_RHR_PULL, engineVersion: 1, secretValues: [
        [envVar: 'RH_REGISTRY_USER', vaultKey: 'user'],
        [envVar: 'RH_REGISTRY_TOKEN', vaultKey: 'token']]]
]

def configuration = [vaultUrl: params.VAULT_ADDRESS, vaultCredentialId: params.VAULT_CREDS_ID, engineVersion: 1]

pipeline {
    agent { label 'rhel8' }
    options {
        timestamps()
        parallelsAlwaysFailFast()
    }
    environment {
        APP_NAME="compliance"
        ARTIFACTS_DIR=""
        CICD_URL="https://raw.githubusercontent.com/RedHatInsights/cicd-tools/main"
        COMPONENT_NAME="compliance"
        COMPONENTS_W_RESOURCES="compliance"
        IMAGE="quay.io/cloudservices/compliance-backend"
        IQE_CJI_TIMEOUT="30m"
        IQE_FILTER_EXPRESSION=""
        IQE_MARKER_EXPRESSION="compliance_smoke"
        IQE_PLUGINS="compliance"
        REF_ENV="insights-stage"
    }

    stages {

        stage('Build the PR commit image') {
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh '''
                    curl -s ${CICD_URL}/bootstrap.sh > .cicd_bootstrap.sh
                    source ./.cicd_bootstrap.sh
                    ./build_deploy.sh
                    '''
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('Run unit tests') {
                    steps {
                        withVault([configuration: configuration, vaultSecrets: secrets]) {
                            sh 'bash -x ./scripts/unit_test.sh'
                        }
                    }
                }
                stage('Run smoke tests') {
                    steps {
                        withVault([configuration: configuration, vaultSecrets: secrets]) {
                            sh '''
                                curl -s ${CICD_URL}/bootstrap.sh > .cicd_bootstrap.sh
                                source ./.cicd_bootstrap.sh
                                source "${CICD_ROOT}/deploy_ephemeral_env.sh"
                                source "${CICD_ROOT}/cji_smoke_test.sh"
                            '''
                        }
                    }
                    post {
                        failure {
                            slackSend  channel: '@eshamard', color: "danger", message: "Smoke tests failed in Compliance PR check. <${env.ghprbPullLink}|PR link>  (<${env.BUILD_URL}|Build>)"
                        }
                        unstable {
                            slackSend  channel: '@eshamard', color: "warning", message: "Smoke tests failed in Compliance PR check. <${env.ghprbPullLink}|PR link>  (<${env.BUILD_URL}|Build>)"
                        }
                    }
                }
            }
        }
    }

    post {
        always{
            archiveArtifacts artifacts: 'artifacts/**/*', fingerprint: true
            junit skipPublishingChecks: true, testResults: 'artifacts/junit-*.xml'
        }
    }
}
