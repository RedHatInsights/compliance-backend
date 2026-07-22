def secrets = [
    [path: 'insights-cicd/ephemeral-bot-svc-account', secretValues: [
        [envVar: 'OC_LOGIN_TOKEN_DEV', vaultKey: 'oc-login-token-dev'],
        [envVar: 'OC_LOGIN_SERVER_DEV', vaultKey: 'oc-login-server-dev'],
        [envVar: 'OC_LOGIN_TOKEN', vaultKey: 'oc-login-token'],
        [envVar: 'OC_LOGIN_SERVER', vaultKey: 'oc-login-server']]],
    [path: 'app-sre/quay/cloudservices-push', secretValues: [
        [envVar: 'QUAY_USER', vaultKey: 'user'],
        [envVar: 'QUAY_TOKEN', vaultKey: 'token']]],
    [path: 'insights-cicd/insightsdroid-github', secretValues: [
        [envVar: 'GITHUB_TOKEN', vaultKey: 'token'],
        [envVar: 'GITHUB_API_URL', vaultKey: 'mirror_url']]],
    [path: 'insights-cicd/rh-registry-pull', secretValues: [
        [envVar: 'RH_REGISTRY_USER', vaultKey: 'user'],
        [envVar: 'RH_REGISTRY_TOKEN', vaultKey: 'token']]]
]

def configuration = [vaultUrl: params.VAULT_ADDRESS, vaultCredentialId: params.VAULT_CREDS_ID]

pipeline {
    agent {
        node {
            label 'rhel8-spot'
        }
    }
    options {
        timestamps()
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
        DEPLOY_TIMEOUT="1200"
    }

    stages {
        stage('Build image') {
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh 'bash -x build_deploy.sh'
                }
            }
        }
        stage('Run smoke tests') {
            when {
                not { branch 'master' }
            }
            steps {
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh '''
                        AVAILABLE_CLUSTERS=('ephemeral' 'crcd')
                        curl -s ${CICD_URL}/bootstrap.sh > .cicd_bootstrap.sh
                        source ./.cicd_bootstrap.sh

                        get_quay_sha() {
                            local quay_repo="$1"
                            local git_repo="$2"
                            local quay_url="https://quay.io/api/v1/repository/${quay_repo}/tag?onlyActiveTags=true&limit=50"
                            local quay_tags=""

                            if ! quay_tags=$(curl -sL --fail --connect-timeout 10 --max-time 30 "$quay_url" 2>/dev/null); then
                                quay_tags=""
                            fi

                            local latest_manifest
                            latest_manifest=$(echo "$quay_tags" | jq -r '.tags[] | select(.name == "latest") | .manifest_digest' 2>/dev/null)

                            local resolved_sha
                            resolved_sha=$(echo "$quay_tags" | jq -r --arg manifest "$latest_manifest" '.tags[] | select(.manifest_digest == $manifest) | .name | select(test("^[0-9a-f]{40}$"))' 2>/dev/null | head -n 1)

                            if [ -z "$resolved_sha" ] || [ "$resolved_sha" = "null" ]; then
                                echo "Warning: Could not resolve full git SHA from Quay 'latest' tag for ${quay_repo}. Falling back to git ls-remote..." >&2
                                resolved_sha=$(git ls-remote "$git_repo" HEAD | cut -f1)
                            fi

                            if ! printf '%s' "$resolved_sha" | grep -Eq '^[0-9a-f]{40}$'; then
                                echo "Error: Could not resolve a valid 40-character commit SHA for ${quay_repo}." >&2
                                exit 1
                            fi

                            echo "$resolved_sha"
                        }

                        USE_QUAY_LATEST_TAG_ONLY="false"

                        if [ "$USE_QUAY_LATEST_TAG_ONLY" = "true" ]; then
                            echo "Option A: Using 'latest' image tag directly for dependency images..."
                            EXTRA_OVERRIDE_ARGS="
                                --set-image-tag quay.io/redhat-services-prod/hcc-accessmanagement-tenant/insights-rbac=latest
                                --set-image-tag quay.io/redhat-services-prod/project-kessel-tenant/kessel-inventory-consumer/inventory-consumer=latest
                                --set-image-tag quay.io/redhat-services-prod/project-kessel-tenant/kessel-inventory/inventory-api=latest
                            "
                        else
                            echo "Option B: Resolving exact Quay commit SHAs for dependency images..."
                            RBAC_SHA=$(get_quay_sha "redhat-services-prod/hcc-accessmanagement-tenant/insights-rbac" "https://github.com/RedHatInsights/insights-rbac.git")
                            RBAC_SHORT_SHA=${RBAC_SHA:0:7}

                            KESSEL_CONSUMER_SHA=$(get_quay_sha "redhat-services-prod/project-kessel-tenant/kessel-inventory-consumer/inventory-consumer" "https://github.com/project-kessel/kessel-inventory-consumer.git")
                            KESSEL_CONSUMER_SHORT_SHA=${KESSEL_CONSUMER_SHA:0:7}

                            KESSEL_INVENTORY_SHA=$(get_quay_sha "redhat-services-prod/project-kessel-tenant/kessel-inventory/inventory-api" "https://github.com/project-kessel/kessel-inventory.git")
                            KESSEL_INVENTORY_SHORT_SHA=${KESSEL_INVENTORY_SHA:0:7}

                            EXTRA_OVERRIDE_ARGS="
                                --set-image-tag quay.io/redhat-services-prod/hcc-accessmanagement-tenant/insights-rbac=${RBAC_SHORT_SHA}
                                --set-template-ref rbac=${RBAC_SHA}
                                --set-image-tag quay.io/redhat-services-prod/project-kessel-tenant/kessel-inventory-consumer/inventory-consumer=${KESSEL_CONSUMER_SHORT_SHA}
                                --set-template-ref kessel-inventory-consumer=${KESSEL_CONSUMER_SHA}
                                --set-image-tag quay.io/redhat-services-prod/project-kessel-tenant/kessel-inventory/inventory-api=${KESSEL_INVENTORY_SHORT_SHA}
                                --set-template-ref kessel-inventory=${KESSEL_INVENTORY_SHA}
                            "
                        fi

                        export APP_NAME="host-inventory kessel rbac compliance"
                        export IMAGE_TAG="${GIT_COMMIT:0:7}"
                        export OPTIONAL_DEPS_METHOD="all"
                        export EXTRA_DEPLOY_ARGS="
                            ${EXTRA_OVERRIDE_ARGS}
                            -p rbac/NOTIFICATIONS_RH_ENABLED=False
                            -p rbac/V2_MIGRATION_APP_EXCLUDE_LIST=approval
                            -p rbac/ROLE_CREATE_ALLOW_LIST=remediations,inventory,policies,advisor,vulnerability,compliance,automation-analytics,notifications,patch,integrations,ros,staleness,config-manager,idmsvc
                            -p rbac/REPLICATION_TO_RELATION_ENABLED=True
                            -p rbac/PARITY_CHECK_INTERVAL_SECONDS=300
                            -p kessel-relations/SPICEDB_QUANTIZATION_INTERVAL=2.5s
                            -p kessel-relations/SPICEDB_QUANTIZATION_STALENESS_PERCENT=0
                            -p host-inventory/BYPASS_RBAC=false
                            -p host-inventory/BYPASS_KESSEL=false
                        "
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
                        source "${CICD_ROOT}/cji_smoke_test.sh" # Floorist smoke tests
                    '''
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'artifacts/**/*', fingerprint: true, allowEmptyArchive: true
            junit allowEmptyResults: true, skipPublishingChecks: true, testResults: 'artifacts/junit-*.xml'
            cleanWs()
        }
    }
}
