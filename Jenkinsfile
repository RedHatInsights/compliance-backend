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

    openShift.withNode(yaml: "openshift/Jenkins/slave_pod_template.yaml") {

        checkout scm

        changedFiles = changedFiles()

        stage("Bundle install") {
            runBundleInstall()
        }

        stage("Prepare the db") {
            withStatusContext.dbMigrate {
                sh "cp config/database.yml.example config/database.yml"
                sh "bundle exec rake db:migrate --trace"
                sh "bundle exec rake db:test:prepare"
            }
        }

        stage("Unit tests") {
            withCredentials([string(credentialsId: "codecov_token", variable: "CODECOV_TOKEN")]) {
                withStatusContext.unitTest {
                    sh "bundle exec rake test:validate"
                }
            }
        }

        if (currentBuild.currentResult == "SUCCESS" &&
            env.BRANCH_NAME == "master" &&
            ("Gemfile.lock" in changedFiles || "Gemfile" in changedFiles || "openshift/Jenkins/Dockerfile" in changedFiles)) {
            // If Gemfiles or Jenknis slave's Dockerfile changed we need to rebuild the jenkins slave image
            stage("Rebuild the image") {
                openshiftBuild(
                    bldCfg: "jenkins-slave-base-centos7-ruby25-openscap",
                    namespace: "jenkins",
                )
            }
        }
    }
}
