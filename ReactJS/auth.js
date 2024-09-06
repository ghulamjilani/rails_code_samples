import { handleApiRequest } from "./apiHandler";
import { BACKEND_API_URL, parseHeaders } from "./config";

// API function for login
export function loginUserRequest(employee_number, phone_number, role) {
  const config = {
    url: `${BACKEND_API_URL}/auth/sign_in`,
    method: "POST",
    data: {
      employee_number: employee_number,
      phone_number: phone_number,
      role: role,
    },
  };
  return handleApiRequest(config);
}

// API function to login user via otp varification
export function verifyOtpRequest(data) {
  const config = {
    url: `${BACKEND_API_URL}/verify-otp`,
    method: "POST",
    data,
    headers: {
      "ngrok-skip-browser-warning": "skip-browser-warning", // only for local development
    },
  };
  return handleApiRequest(config);
}

// API function to resend the otp code
export function resendOtpRequest(userID) {
  const config = {
    url: `${BACKEND_API_URL}/resend-otp?id=${userID}`,
    method: "GET",
    headers: {
      "ngrok-skip-browser-warning": "skip-browser-warning", // only for local development
    },
  };
  return handleApiRequest(config);
}

// API function to get user data
export function getUser(headers) {
  headers = parseHeaders(headers);
  headers["ngrok-skip-browser-warning"] = "skip-browser-warning"; // only for local development

  const config = {
    url: `${BACKEND_API_URL}/user`,
    method: "GET",
    headers: headers,
  };
  return handleApiRequest(config);
}

export function updateProfileRequest(data, headers) {
  headers = parseHeaders(headers);
  headers["ngrok-skip-browser-warning"] = "skip-browser-warning"; // only for local development

  const config = {
    url: `${BACKEND_API_URL}/auth`,
    method: "PUT",
    data: data,
    headers: headers,
  };
  return handleApiRequest(config);
}
