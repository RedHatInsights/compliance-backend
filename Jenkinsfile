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

                        COMPLIANCE_SHA=$(git ls-remote https://github.com/RedHatInsights/compliance-backend.git HEAD | cut -f1)
                        COMPLIANCE_SHORT_SHA=${COMPLIANCE_SHA:0:7}

                        RBAC_SHA=$(git ls-remote https://github.com/RedHatInsights/insights-rbac.git HEAD | cut -f1)
                        RBAC_SHORT_SHA=${RBAC_SHA:0:7}

                        NAMESPACE=$(bonfire namespace reserve --duration 10h)
                        oc project $NAMESPACE

                        bonfire deploy compliance \
                            --source appsre \
                            --ref-env insights-production \
                            --timeout 900 \
                            --optional-deps-method all \
                            --frontends false \
                            --set-image-tag quay.io/cloudservices/compliance-backend=${COMPLIANCE_SHORT_SHA} \
                            --set-template-ref compliance=${COMPLIANCE_SHA} \
                            --set-image-tag quay.io/redhat-services-prod/hcc-accessmanagement-tenant/insights-rbac=${RBAC_SHORT_SHA} \
                            --set-template-ref rbac=${RBAC_SHA} \
                            -p rbac/NOTIFICATIONS_RH_ENABLED=False \
                            -p rbac/V2_MIGRATION_APP_EXCLUDE_LIST="approval" \
                            -p rbac/ROLE_CREATE_ALLOW_LIST="remediations,inventory,policies,advisor,vulnerability,compliance,automation-analytics,notifications,patch,integrations,ros,staleness,config-manager,idmsvc" \
                            -p rbac/REPLICATION_TO_RELATION_ENABLED=True \
                            -p rbac/PARITY_CHECK_INTERVAL_SECONDS=300 \
                            -p kessel-relations/SPICEDB_QUANTIZATION_INTERVAL=2.5s \
                            -p kessel-relations/SPICEDB_QUANTIZATION_STALENESS_PERCENT=0 \
                            -p host-inventory/BYPASS_RBAC=false \
                            -p host-inventory/BYPASS_KESSEL=false \
                            -n $NAMESPACE

                        # Deploy the RBAC Debezium outbox connector (required when BYPASS_KESSEL=false).
                        # Debezium captures RBAC workspace creation events from management_outbox and
                        # publishes them to outbox.event.workspace so HBI mq-workspaces can populate
                        # hbi.groups, unblocking HBI p1's wait_for_workspace_event() call.
                        oc wait kafkaconnect/kessel-kafka-connect -n $NAMESPACE \
                            --for=condition=Ready --timeout=300s
                        oc apply -n $NAMESPACE -f - <<'CONNECTOR_EOF'
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaConnector
metadata:
  name: rbac-outbox-connector
  labels:
    strimzi.io/cluster: kessel-kafka-connect
spec:
  class: io.debezium.connector.postgresql.PostgresConnector
  tasksMax: 1
  state: running
  config:
    database.hostname: "${secrets:rbac-db:db.host}"
    database.port: "${secrets:rbac-db:db.port}"
    database.user: "${secrets:rbac-db:db.user}"
    database.password: "${secrets:rbac-db:db.password}"
    database.dbname: "${secrets:rbac-db:db.name}"
    database.server.name: "rbac-db"
    topic.prefix: "rbac"
    table.include.list: "public.management_outbox"
    publication.name: "rbac_outbox_pub"
    publication.autocreate.mode: "filtered"
    plugin.name: "pgoutput"
    slot.name: "debezium_rbac_outbox"
    snapshot.mode: "no_data"
    poll.interval.ms: "250"
    transforms: "outbox"
    transforms.outbox.type: "io.debezium.transforms.outbox.EventRouter"
    value.converter: "org.apache.kafka.connect.json.JsonConverter"
    heartbeat.interval.ms: "300000"
    topic.heartbeat.prefix: "debezium-heartbeat"
CONNECTOR_EOF

                        export NAMESPACE
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
