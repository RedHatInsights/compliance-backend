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

        // CICD_TOOLS_URL='https://raw.githubusercontent.com/RedHatInsights/cicd-tools/main/src/bootstrap.sh'
    }

    stages {
        stage('Run Tests') {
            parallel {
                stage('Build the PR commit image') {
                    steps {
                        withVault([configuration: configuration, vaultSecrets: secrets]) {
                            sh '''
                            env

                            bash -x build_deploy.sh
                            '''
                        }
                    }
                }

                // stage('Run unit tests') {
                //     steps {
                //         withVault([configuration: configuration, vaultSecrets: secrets]) {
                //             sh 'bash -x ./scripts/unit_test.sh'
                //         }
                //     }
                // }

                stage('Deploy Ephemeral Environment & Components') {
                    environment {
                        RELEASE_NAMESPACE="false"
                    }
                    steps {
                        withVault([configuration: configuration, vaultSecrets: secrets]) {
                            sh '''
                                curl -s ${CICD_URL}/bootstrap.sh > .cicd_bootstrap.sh
                                source ./.cicd_bootstrap.sh

                                PREVIOUS_COMMIT_HASH=$(git rev-parse --short=7 HEAD^)
                                GIT_COMMIT=$(git rev-parse HEAD^)
                                IMAGE_TAG="pr-${ghprbPullId}-${PREVIOUS_COMMIT_HASH}"

                                source "${CICD_ROOT}/deploy_ephemeral_env.sh"

                                > reserved_namespace
                                echo "$NAMESPACE" >> reserved_namespace
                            '''
                        }

                        script {
                            env.NAMESPACE = readFile('reserved_namespace')
                        }
                    }
                }
            }
        }

        stage('2nd Stage') {
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {

                    sh '''
                        curl -s ${CICD_URL}/bootstrap.sh > .cicd_bootstrap.sh
                        source ./.cicd_bootstrap.sh
                        
                        IMAGE="quay.io/cloudservices/compliance-backend"

                        source "${CICD_ROOT}/_common_deploy_logic.sh"

                        set -x
                        bonfire deploy \
                            ${APP_NAME} \
                            --source=appsre \
                            --ref-env ${REF_ENV} \
                            --set-image-tag ${IMAGE}=${IMAGE_TAG} \
                            --namespace ${NAMESPACE} \
                            --timeout ${DEPLOY_TIMEOUT} \
                            ${TEMPLATE_REF_ARG} \
                            ${COMPONENTS_ARG} \
                            ${COMPONENTS_RESOURCES_ARG} \
                            ${EXTRA_DEPLOY_ARGS}
                    
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
