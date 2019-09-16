/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/RedHatInsights/insights-pipeline-lib") _

node {
    cancelPriorBuilds()

    echo "here"
    milestone()

    runIfMasterOrPullReq {
        runStages()
    }
}

def runStages() {

    openShift.withNode(
        cloud: "openshift",
        namespace: "jenkins",
        yaml: "openshift/Jenkins/slave_pod_template.yaml",
        image: "jenkins-slave-rhel7-ruby25-openscap:latest",
        limitMemory: "2Gi"
    ) {
        checkout scm

        stageWithContext("Bundle-install", shortenURL = false) {
            sh "bundle install"
        }

        stageWithContext("Prepare-db", shortenURL = false) {
            sh "bundle exec rake db:migrate --trace"
            sh "bundle exec rake db:test:prepare"
        }

        stageWithContext("Unit-tests", shortenURL = false) {
            withCredentials([string(credentialsId: "codecov_token", variable: "CODECOV_TOKEN")]) {
                sh "bundle exec rake test:validate"
            }
        }
    }

    scmVars = checkout scm

    if (currentBuild.currentResult == "SUCCESS" && env.CHANGE_TARGET == "stable" && env.CHANGE_ID) {
        runSmokeTest (
            ocDeployerBuilderPath: "compliance/compliance-backend",
            ocDeployerComponentPath: "compliance/compliance-backend",
            ocDeployerServiceSets: "compliance,platform,platform-mq",
            iqePlugins: ["iqe-compliance-plugin"],
            pytestMarker: "compliance_smoke",
        )
    }

    if (currentBuild.currentResult == "SUCCESS" && env.CHANGE_TARGET == "master" && !env.CHANGE_ID) {

        changedFiles = changedFiles()

        if ("Gemfile.lock" in changedFiles || "Gemfile" in changedFiles || "openshift/Jenkins/Dockerfile" in changedFiles) {
            // If Gemfiles or Jenknis slave's Dockerfile changed we need to rebuild the jenkins slave image
            stageWithContext("Rebuild-jenkins-slave", shortenURL = false) {
                openshift.withCluster("openshift") {
                    openshift.startBuild("jenkins-slave-rhel7-ruby25-openscap")
                }
            }
        }

        stageWithContext("Wait-until-deployed", shortenURL = false) {
            waitForDeployment(
                cluster: "openshift",
                credentials: "compliance-token",
                project: "compliance-ci",
                label: "app",
                value: "compliance-backend",
                gitCommit: scmVars.GIT_COMMIT,
                minutes: 20
            )
        }

        openShift.withNode(
            cloud: "openshift",
            image: pipelineVars.jenkinsSlaveIqeImage,
            workingDir: "/tmp",
            namespace: "jenkins",
        ) {
            stageWithContext("Install-integration-tests", shortenURL = false) {
                sh "iqe plugin install compliance"
            }

            stageWithContext("Inject-settings", shortenURL = false) {
                withCredentials([
                    file(credentialsId: "compliance-settings-credentials-yaml", variable: "creds"),
                    file(credentialsId: "compliance-settings-local-yaml", variable: "settings")]
                ) {
                    sh "cp \$creds \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                    sh "cp \$settings \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                }
            }

            stageWithContext("Run-smoke-tests", shortenURL = false) {
                withEnv(["ENV_FOR_DYNACONF=ci"]) {
                   sh "iqe tests plugin compliance -v -s -m compliance_smoke --junitxml=junit.xml"
                }
                junit "junit.xml"
            }
        }
    }
}
