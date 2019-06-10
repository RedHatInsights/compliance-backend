/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/RedHatInsights/insights-pipeline-lib") _

node {
    cancelPriorBuilds()

    runIfMasterOrPullReq {
        runStages()
    }
}

def runStages() {

    openShift.withNode(
        cloud: "upshift",
        namespace: "insights-qe-ci",
        yaml: "openshift/Jenkins/slave_pod_template.yaml",
        image: "jenkins-slave-base-centos7-ruby25-openscap:latest",
        limitMemory: "2Gi"
    ) {
        checkout scm

        stageWithContext("Bundle_install") {
            sh "bundle install"
        }

        stageWithContext("Prepare_db") {
            sh "bundle exec rake db:migrate --trace"
            sh "bundle exec rake db:test:prepare"
        }

        stageWithContext("Unit_tests") {
            withCredentials([string(credentialsId: "codecov_token", variable: "CODECOV_TOKEN")]) {
                sh "bundle exec rake test:validate"
            }
        }
    }

    scmVars = checkout scm

    if (currentBuild.currentResult == "SUCCESS" && env.BRANCH_NAME == "master") {

        changedFiles = changedFiles()

        if ("Gemfile.lock" in changedFiles || "Gemfile" in changedFiles || "openshift/Jenkins/Dockerfile" in changedFiles) {
            // If Gemfiles or Jenknis slave's Dockerfile changed we need to rebuild the jenkins slave image
            stageWithContext("Rebuild_jenkins_slave") {
                openshift.withCluster("upshift") {
                    openshift.startBuild("jenkins-slave-base-centos7-ruby25-openscap")
                }
            }
        }

        stageWithContext("Wait_until_deployed") {
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

        openShift.withNode(
            cloud: "upshift",
            image: pipelineVars.jenkinsSlaveIqeImage,
            workingDir: "/tmp",
            namespace: "insights-qe-ci",
        ) {
            stageWithContext("Install_integration_tests") {
                sh "iqe plugin install compliance"
            }

            stageWithContext("Inject_credentials_and_settings") {
                withCredentials([
                    file(credentialsId: "compliance-settings-credentials-yaml", variable: "creds"),
                    file(credentialsId: "compliance-settings-local-yaml", variable: "settings")]
                ) {
                    sh "cp \$creds \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                    sh "cp \$settings \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                }
            }

            stageWithContext("Run_smoke_tests") {
                withEnv(["ENV_FOR_DYNACONF=ci"]) {
                   sh "iqe tests plugin compliance -v -s -m compliance_smoke --junitxml=junit.xml"
                }
                junit "junit.xml"
            }
        }

        if (currentBuild.currentResult == "SUCCESS") {
            stageWithContext("Tag_image") {
                openshift.withCluster("dev_cluster") {
                    openshift.withCredentials("jenkins-sa-dev-cluster") {
                        openshift.withProject("buildfactory") {
                            openshift.tag("compliance-backend:latest", "compliance-backend:stable")
                        }
                    }
                }
            }
        }
    }
}
