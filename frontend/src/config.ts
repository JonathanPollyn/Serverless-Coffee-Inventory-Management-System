// Switch between real AWS API and local mock data.
// Use MOCK_MODE=true when DNS/network is flaky.
export const MOCK_MODE = true

// When MOCK_MODE=false, this must be your API Gateway base URL.
export const API_URL = "https://olq802cb0e.execute-api.us-east-1.amazonaws.com/prod"