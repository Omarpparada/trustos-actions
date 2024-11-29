const core = require('@actions/core')

const { login } = require('./trustos')

async function run() {
  try {
    const directory = core.getInput('directory')
    const apiUser = core.getInput('api_user', { required: true })
    const apiPassword = core.getInput('api_password', { required: true })

    const token = login(apiUser, apiPassword)
    core.setOutput('token', token)
  } catch (error) {
    core.setFailed(error.message)
  }
}

run()
