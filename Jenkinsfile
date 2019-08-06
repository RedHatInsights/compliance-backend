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

        stageWithContext("Bundle-install") {
            sh "bundle install"
        }

        stageWithContext("Prepare-db") {
            sh "bundle exec rake db:migrate --trace"
            sh "bundle exec rake db:test:prepare"
        }

        stageWithContext("Unit-tests") {
            withCredentials([string(credentialsId: "codecov_token", variable: "CODECOV_TOKEN")]) {
                sh "bundle exec rake test:validate"
            }
        }
    }

    scmVars = checkout scm

    println(env)

    if (currentBuild.currentResult == "SUCCESS" && env.BRANCH_NAME == "master" && !env.CHANGE_ID) {

        changedFiles = changedFiles()

        if ("Gemfile.lock" in changedFiles || "Gemfile" in changedFiles || "openshift/Jenkins/Dockerfile" in changedFiles) {
            // If Gemfiles or Jenknis slave's Dockerfile changed we need to rebuild the jenkins slave image
            stageWithContext("Rebuild-jenkins-slave") {
                openshift.withCluster("upshift") {
                    openshift.startBuild("jenkins-slave-base-centos7-ruby25-openscap")
                }
            }
        }

        stageWithContext("Wait-until-deployed") {
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
            stageWithContext("Install-integration-tests") {
                sh "iqe plugin install compliance"
            }

            stageWithContext("Inject-settings") {
                withCredentials([
                    file(credentialsId: "compliance-settings-credentials-yaml", variable: "creds"),
                    file(credentialsId: "compliance-settings-local-yaml", variable: "settings")]
                ) {
                    sh "cp \$creds \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                    sh "cp \$settings \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                }
            }

            stageWithContext("Run-smoke-tests") {
                withEnv(["ENV_FOR_DYNACONF=ci"]) {
                   sh "iqe tests plugin compliance -v -s -m compliance_smoke --junitxml=junit.xml"
                }
                junit "junit.xml"
            }
        }
    }
}
