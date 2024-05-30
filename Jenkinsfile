def secrets = [
    [path: params.VAULT_PATH_INSIGHTSDROID_GITHUB, secretValues: [
        [envVar: 'GITHUB_TOKEN', vaultKey: 'token'],
        [envVar: 'GITHUB_API_URL', vaultKey: 'mirror_url']]],
]

def configuration = [vaultUrl: params.VAULT_ADDRESS, vaultCredentialId: params.VAULT_CREDS_ID]

pipeline {
    agent { label 'rhel8' }
    options {
        timestamps()
    }
    stages {
        stage('Test notifying back ot the PR') {
            steps {
                sh "echo 'a step'"
            }
        }
    }

    post {
        always{
            githubPRComment("finished!")
            }
        }
    }
}
