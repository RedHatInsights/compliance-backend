/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/quarckster/insights-pipeline-lib@fix") _

node {
    cancelPriorBuilds()

    runIfMasterOrPullReq {
        runStages()
    }
}

def runStages() {

    def label = "test-${UUID.randomUUID().toString()}"

    podTemplate(
        cloud: "cmqe",
        name: "compliance-backend-test",
        label: label,
        inheritFrom: "compliance-backend-test",
        serviceAccount: pipelineVars.jenkinsSvcAccount
    ) {
        node(label) {

            checkout scm

            stage("Bundle_install") {
                runBundleInstall()
            }

            stage("Prepare_db") {
                withStatusContext.custom(env.STAGE_NAME, true) {
                    sh "bundle exec rake db:migrate --trace"
                    sh "bundle exec rake db:test:prepare"
                }
            }

            stage("Unit_tests") {
                withCredentials([string(credentialsId: "codecov_token", variable: "CODECOV_TOKEN")]) {
                    withStatusContext.custom(env.STAGE_NAME, true) {
                        sh "bundle exec rake test:validate"
                    }
                }
            }
        }
    }

    scmVars = checkout scm

    if (currentBuild.currentResult == "SUCCESS" && env.BRANCH_NAME == "master") {

        changedFiles = changedFiles()

        if ("Gemfile.lock" in changedFiles || "Gemfile" in changedFiles || "openshift/Jenkins/Dockerfile" in changedFiles) {
            // If Gemfiles or Jenknis slave's Dockerfile changed we need to rebuild the jenkins slave image
            stage("Rebuild_jenkins_slave") {
                openshift.withCluster("cmqe") {
                    withStatusContext.custom(env.STAGE_NAME, true) {
                        openshift.startBuild("jenkins-slave-base-centos7-ruby25-openscap")
                    }
                }
            }
        }

        stage("Wait_until_deployed") {
            withStatusContext.custom(env.STAGE_NAME, true) {
                waitForDeployment(
                    cluster: "dev_cluster",
                    credentials: "compliance-token",
                    project: "compliance-ci",
                    label: "app",
                    value: "compliance-backend",
                    gitCommit: scmVars.GIT_COMMIT,
                    minutes: 20
                )
            }
        }

        openShift.withNode(cloud: "cmqe", image: pipelineVars.jenkinsSlaveIqeImage, workingDir: "") {
            stage("Install_integration_tests") {
                withStatusContext.custom(env.STAGE_NAME, true) {
                    sh "iqe plugin install compliance"
                    sh "iqe plugin install red-hat-internal-envs"
                }
            }

            stage("Inject_credentials_and_settings") {
                withCredentials([
                    file(credentialsId: "compliance-settings-credentials-yaml", variable: "creds"),
                    file(credentialsId: "compliance-settings-local-yaml", variable: "settings")]
                ) {
                    withStatusContext.custom(env.STAGE_NAME, true) {
                        sh "cp \$creds \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                        sh "cp \$settings \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                    }
                }
            }

            stage("Run_integration_tests") {
                withStatusContext.custom(env.STAGE_NAME, true) {
                    withEnv(["ENV_FOR_DYNACONF=ci"]) {
                       sh "iqe tests plugin compliance -v -s -m tier0"
                    }
                }
            }
        }
    }
}
