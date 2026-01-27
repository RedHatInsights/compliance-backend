def secrets = [
    [path: params.VAULT_PATH_SVC_ACCOUNT_EPHEMERAL, secretValues: [
        [envVar: 'OC_LOGIN_TOKEN_DEV', vaultKey: 'oc-login-token-dev'],
        [envVar: 'OC_LOGIN_SERVER_DEV', vaultKey: 'oc-login-server-dev'],
        [envVar: 'OC_LOGIN_TOKEN', vaultKey: 'oc-login-token'],
        [envVar: 'OC_LOGIN_SERVER', vaultKey: 'oc-login-server']]],
    [path: params.VAULT_PATH_QUAY_PUSH, secretValues: [
        [envVar: 'QUAY_USER', vaultKey: 'user'],
        [envVar: 'QUAY_TOKEN', vaultKey: 'token']]],
    [path: params.VAULT_PATH_INSIGHTSDROID_GITHUB, secretValues: [
        [envVar: 'GITHUB_TOKEN', vaultKey: 'token'],
        [envVar: 'GITHUB_API_URL', vaultKey: 'mirror_url']]],
    [path: params.VAULT_PATH_RHR_PULL, secretValues: [
        [envVar: 'RH_REGISTRY_USER', vaultKey: 'user'],
        [envVar: 'RH_REGISTRY_TOKEN', vaultKey: 'token']]]
]

def configuration = [vaultUrl: params.VAULT_ADDRESS, vaultCredentialId: params.VAULT_CREDS_ID]

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
        IMAGE="quay.io/cloudservices/compliance-backend"
        IQE_CJI_TIMEOUT="30m"
        IQE_FILTER_EXPRESSION=""
        IQE_MARKER_EXPRESSION="compliance_smoke"
        IQE_PLUGINS="compliance"
        REF_ENV="insights-production"
    }

    stages {

        stage('Build the PR commit image') {
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh 'bash -x build_deploy.sh'
                }
            }
        }
        stage('Run smoke tests') {
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh '''
                        AVAILABLE_CLUSTERS=('ephemeral' 'crcd')
                        curl -s ${CICD_URL}/bootstrap.sh > .cicd_bootstrap.sh
                        source ./.cicd_bootstrap.sh
                        source "${CICD_ROOT}/deploy_ephemeral_env.sh"
                        source "${CICD_ROOT}/cji_smoke_test.sh"

                        # Update IQE plugin config to run floorist plugin tests.
                        export COMPONENT_NAME="compliance"
                        export IQE_CJI_NAME="floorist"
                        # Pass in COMPONENT_NAME.
                        export IQE_ENV_VARS="COMPONENT_NAME=$COMPONENT_NAME"
                        export IQE_PLUGINS="floorist"
                        export IQE_MARKER_EXPRESSION="floorist_smoke"
                        export IQE_IMAGE_TAG="floorist"

                        # Run smoke tests with ClowdJobInvocation
                        source "${CICD_ROOT}/cji_smoke_test.sh"
                    '''
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
