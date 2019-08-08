@Library("github.com/RedHatInsights/insights-pipeline-lib") _

if (env.CHANGE_ID) {
    runSmokeTest (
        ocDeployerBuilderPath: "compliance/compliance-backend",
        ocDeployerComponentPath: "compliance/compliance-backend",
        ocDeployerServiceSets: "compliance,platform,platform-mq",
        iqePlugins: ["iqe-compliance-plugin"],
        pytestMarker: "compliance_smoke",
    )
}
