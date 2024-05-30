def secrets = [
    [path: params.VAULT_PATH_INSIGHTSDROID_GITHUB, secretValues: [
        [envVar: 'GITHUB_TOKEN', vaultKey: 'token'],
        [envVar: 'GITHUB_API_URL', vaultKey: 'mirror_url']]],
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
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                    sh '''
                        export text_pr="This is a comment"
                        curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
                        -X POST -d '{"body": "$text_pr"}' "${GITHUB_API_URL}/repos/${ghprbGhRepository}/issues/${ghprbPullId}/comments"
                    '''

                }

            }
        }
    }

    post {
        always{
            sh "echo 'done!'"
        }
    }
}
