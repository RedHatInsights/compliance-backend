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

            stage("Bundle install") {
                runBundleInstall()
            }

            stage("Prepare the db") {
                withStatusContext.dbMigrate {
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
        }
    }

    scmVars = checkout scm

    if (currentBuild.currentResult == "SUCCESS" && env.BRANCH_NAME == "master") {

        changedFiles = changedFiles()

        if ("Gemfile.lock" in changedFiles || "Gemfile" in changedFiles || "openshift/Jenkins/Dockerfile" in changedFiles) {
            // If Gemfiles or Jenknis slave's Dockerfile changed we need to rebuild the jenkins slave image
            stage("Rebuild the jenkins slave ruby image") {
                openshift.withCluster("cmqe") {
                    openshift.startBuild("jenkins-slave-base-centos7-ruby25-openscap")
                }
            }
        }


        openshift.withCluster("dev_cluster") {
            openshift.withCredentials("compliance-token") {
                openshift.withProject("compliance-ci") {
                    stage("Wait until deployed") {
                        parallel(
                            "API": {
                                timeout(20) {
                                    def finished = false
                                    waitUntil {
                                        try {
                                            def pod = openshift.selector("pod", [name : "compliance-backend"]).name()
                                            if (openshift.rsh("${pod} git rev-parse HEAD").out.trim() == scmVars.GIT_COMMIT) {
                                                waitUntil {
                                                    def lastRc = openshift.selector("rc", [app : "compliance-backend"]).objects()[-1]
                                                    finished = lastRc.status.replicas == lastRc.status.readyReplicas
                                                    return finished
                                                }
                                            }
                                            return finished
                                        } catch(e) {
                                            return false
                                        }
                                    }
                                }
                            },
                            "Consumer": {
                                timeout(20) {
                                    def finished = false
                                    waitUntil {
                                        try {
                                            def pod = openshift.selector("pod", [name : "compliance-consumer"]).name()
                                            if (openshift.rsh("${pod} git rev-parse HEAD").out.trim() == scmVars.GIT_COMMIT) {
                                                waitUntil {
                                                    def lastRc = openshift.selector("rc", [app : "compliance-consumer"]).objects()[-1]
                                                    finished = lastRc.status.replicas == lastRc.status.readyReplicas
                                                    return finished
                                                }
                                            }
                                            return finished
                                        } catch(e) {
                                            return false
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }

        def iqeLabel = "test-${UUID.randomUUID().toString()}"

        podTemplate(
            cloud: "cmqe",
            name: "compliance-backend-integration-tests",
            label: iqeLabel,
            serviceAccount: pipelineVars.jenkinsSvcAccount,
            containers: [
                containerTemplate(
                    name: "jnlp",
                    image: pipelineVars.jenkinsSlaveIqeImage,
                    workingDir: ""
                )
            ]
        ) {
            node(iqeLabel) {
                stage("Install integration tests env") {
                    sh "iqe plugin install iqe-compliance-plugin"
                    sh "iqe plugin install iqe-red-hat-internal-envs-plugin"
                }

                stage("Inject credentials and settings") {
                    withCredentials([
                        file(credentialsId: "compliance-settings-credentials-yaml", variable: "creds"),
                        file(credentialsId: "compliance-settings-local-yaml", variable: "settings")]
                    ) {
                        sh "cp \$creds \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                        sh "cp \$settings \$IQE_VENV/lib/python3.6/site-packages/iqe_compliance/conf"
                    }
                }

                stage("Run integration tests") {
                    withStatusContext.integrationTest {
                        withEnv(["ENV_FOR_DYNACONF=ci"]) {
                           sh "iqe tests plugin compliance -v -s -k 'test_validate_compliance_report or test_graphql_smoke'"    
                        }
                    }
                }
            }
        }
    }
}
