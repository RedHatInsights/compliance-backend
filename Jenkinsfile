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
    openShift.withNode(image: "docker-registry.default.svc:5000/jenkins/jenkins-slave-base-centos7-ruby25-openscap:latest", resourceLimitMemory: "2Gi") {

        scmVars = checkout scm
        
        stage('Install gems') {
            sh "bundle install --path /tmp"
        }

        stage('Prepare the db') {
            sh "bundle exec rake db:migrate --trace"
            sh "bundle exec rake db:test:prepare"
        }

        stage('UnitTest') {
            withStatusContext.unitTest {
                sh "bundle exec rake validate"
            }
        }

        if (currentBuild.currentResult == 'SUCCESS') {
            if (env.BRANCH_NAME == 'master') {
                // Stages to run specifically if master branch was updated
            }
        }
    }
}
