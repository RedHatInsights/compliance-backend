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
            sh "bundle install --path /tmp/bundle"
        }

        gitUtils.stageWithContext("Prepare-db", shortenURL = false) {
            sh "bundle exec rake db:migrate --trace"
            sh "bundle exec rake db:test:prepare"
        }

        gitUtils.stageWithContext("Unit-tests", shortenURL = false) {
            withCredentials([string(credentialsId: "codecov_token", variable: "CODECOV_TOKEN")]) {
                sh "bundle exec rake test:validate"
            }
        }
    }

    scmVars = checkout scm

    if (currentBuild.currentResult == "SUCCESS" && env.CHANGE_TARGET == "stable" && env.CHANGE_ID) {
        execSmokeTest (
            ocDeployerBuilderPath: "compliance/compliance-backend",
            ocDeployerComponentPath: "compliance/compliance-backend",
            ocDeployerServiceSets: "compliance,platform,platform-mq",
            iqePlugins: ["iqe-compliance-plugin"],
            pytestMarker: "compliance_smoke",
        )
    }
}
