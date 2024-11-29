const axios = require('axios')
const { generateKongToken } = require('./utils.js')

const TRUSTOS_LAB_URL = 'https://lab.trustos.telefonicatech.com';
const TRUSTOS_PROD_URL = 'https://apis.trustos.telefonicatech.com';

export async function login(username, password, env = 'lab') {
    const TRUSTOS_API_URL = env === 'lab' ? TRUSTOS_LAB_URL : TRUSTOS_PROD_URL
    try {
        const kongHeader = { kongAuth: `Bearer ${await generateKongToken()}` }
        const response = await axios.post(`${TRUSTOS_API_URL}/id/v2/login`, {
            username,
            password
        },
        {
            headers: kongHeader
        });
        return response.data.data.token;
    } catch (error) {
        if (error.response) {
            core.info('Response details:');
            core.info(`Status: ${error.response.status}`);
            core.info(`Response data: ${JSON.stringify(error.response.data)}`);
            core.info(`Response headers: ${JSON.stringify(error.response.headers)}`);
          }
        throw error;
    }
}

export async function createCertificate(token, hash) {
    const response = await axios.post(`${TRUSTOS_API_URL}/cert/v2/certificates?networkId=10004`, {
        name: 'Certification from TrustOS Actions',
        description: 'This is a certification from TrustOS Actions',
        content: {
            hash: hash
        }
    }, {
        headers: {
            Authorization: `Bearer ${token}`
        }
    })

    return response.data.data.certID;
}

//login().then(token => createCertificate(token, 'hash'));