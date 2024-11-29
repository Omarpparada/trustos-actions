const { STSClient, AssumeRoleCommand } = require('@aws-sdk/client-sts')
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm')

const AWS_REGION = 'eu-west-1'

const stsClient = new STSClient({
  region: AWS_REGION
})

async function getCredentials() {
    const roleArn = process.env.AWS_ROLE_ARN
    if (!roleArn) {
        throw new Error('AWS_ROLE_ARN environment variable is not set');
      }
    const params = {
      RoleArn: roleArn,
      RoleSessionName: 'GithubActionSession'
    };
  
    const command = new AssumeRoleCommand(params)
    const response = await stsClient.send(command)
  
    return {
      accessKeyId: response.Credentials.AccessKeyId,
      secretAccessKey: response.Credentials.SecretAccessKey,
      sessionToken: response.Credentials.SessionToken
    };
  }

  async function createSSMClient() {
    const credentials = await getCredentials();
    return new SSMClient({
      region: AWS_REGION,
      credentials: credentials
    });
  }

export async function generateKongToken () {
    const client = await createSSMClient()
    const command = new GetParameterCommand({
      Name: '/ref/kong_secret_key_jwt',
      WithDecryption: true
    })
    const { Parameter: { Value: secretKey } } = await client.send(command)
    const payload = {
      iss: 'ref-github-jwt',
      exp: Math.floor(Date.now() / 1000) + (10 * 60) // Expira en 10 minutos
    }
    const token = jwt.sign(payload, secretKey, { algorithm: 'HS256' })
    return token
  }