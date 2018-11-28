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

def filesChanged() {
    def affectedFiles = []
    currentBuild.changeSets.each { changeSet ->
        changeSet.items.each { entry ->
            entry.affectedFiles.each { file ->
                affectedFiles.add(file.path)
            }
        }
    }
    "Gemfile" in affectedFiles || "openshift/Jenkins/Dockerfile" in affectedFiles
}

def runStages() {
    openShift.withNode(image: "docker-registry.default.svc:5000/jenkins/jenkins-slave-base-centos7-ruby25-openscap:latest") {
        
        checkout scm

        if (filesChanged()) {
            stage("Bundle install") {
                runBundleInstall()
            }            
        }

        stage("Prepare the db") {
            withStatusContext.dbMigrate {
                sh "bundle exec rake db:migrate --trace"
                sh "bundle exec rake db:test:prepare"
            }
        }

        stage("Unit tests") {
            withStatusContext.unitTest {
                sh "bundle exec rake validate"
            }
        }

        if (currentBuild.currentResult == "SUCCESS" && env.BRANCH_NAME == "master" && filesChanged()) {
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
