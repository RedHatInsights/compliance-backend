def secrets = [
    [path: params.VAULT_PATH_SVC_ACCOUNT_EPHEMERAL, engineVersion: 1, secretValues: [
        [envVar: 'OC_LOGIN_TOKEN_DEV', vaultKey: 'oc-login-token-dev'],
        [envVar: 'OC_LOGIN_SERVER_DEV', vaultKey: 'oc-login-server-dev']]],
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
    }
    environment {
        APP_NAME="compliance"
        COMPONENT_NAME="compliance"
        IMAGE="quay.io/cloudservices/compliance-backend"
        IQE_PLUGINS="compliance"
        IQE_MARKER_EXPRESSION="compliance_smoke"
        IQE_FILTER_EXPRESSION=""
        IQE_CJI_TIMEOUT="30m"
        REF_ENV="insights-stage"
        COMPONENTS_W_RESOURCES="compliance"
        ARTIFACTS_DIR=""

        CICD_URL="https://raw.githubusercontent.com/RedHatInsights/cicd-tools/main"
    }

    stages {
        stage('Build the PR commit image') {
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh '''
                    curl -s ${CICD_URL}/bootstrap.sh > .cicd_bootstrap.sh
                    source ./.cicd_bootstrap.sh
                    source ./build_deploy.sh
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
