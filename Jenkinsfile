/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/RedHatInsights/insights-pipeline-lib@v3") _

node {
    pipelineUtils.cancelPriorBuilds()

    pipelineUtils.runIfMasterOrPullReq {
        runStages()
    }
}

def runStages() {

    openShiftUtils.withNode(yaml: "openshift/Jenkins/slave_pod_template.yaml") {
        checkout scm

        gitUtils.stageWithContext("Bundle-install", shortenURL = false) {
            bundleStatus = sh(script: "bundle install --path /tmp/bundle", returnStatus: true)
        }

        if (bundleStatus != 0) {
          error("Bundle-install failed")
        }

        gitUtils.stageWithContext("Prepare-db", shortenURL = false) {
            migrateStatus = sh(script: "bundle exec rake db:test:prepare --trace", returnStatus: true)
            sh "bundle exec rails db:environment:set RAILS_ENV=test"
            container("postgresql") {
              sh("psql compliance < db/cyndi_setup_test.sql")
            }
        }

        if (migrateStatus != 0) {
          error("DB migrations failed")
        }

        gitUtils.stageWithContext("Unit-tests", shortenURL = false) {
            withCredentials([string(credentialsId: "codecov_token", variable: "CODECOV_TOKEN")]) {
                sh "bundle exec rake test:validate"
            }
        }
    }

    scmVars = checkout scm

    if (currentBuild.currentResult == "SUCCESS" && env.CHANGE_TARGET in ["master", "stable"] && env.CHANGE_ID) {
        execSmokeTest (
            ocDeployerBuilderPath: "compliance/compliance-backend",
            ocDeployerComponentPath: "compliance",
            ocDeployerServiceSets: "compliance,ingress,inventory,platform-mq,rbac,cyndi",
            iqePlugins: ["iqe-compliance-plugin"],
            pytestMarker: "compliance_smoke",
        )
    }
}
