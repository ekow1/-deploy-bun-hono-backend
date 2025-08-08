import React from "react";

const CodeVerificationEmail = ({ username, code }) => (
  <div style={{ fontFamily: "Arial, sans-serif", background: "#f9f9f9", padding: "32px" }}>
    <div style={{ maxWidth: "480px", margin: "0 auto", background: "#fff", borderRadius: "8px", boxShadow: "0 2px 8px rgba(0,0,0,0.05)", padding: "32px" }}>
      <h2 style={{ color: "#333", marginBottom: "16px" }}>Verify Your Email Address</h2>
      <p style={{ color: "#555", fontSize: "16px" }}>
        Hi{username ? ` ${username}` : ""},
      </p>
      <p style={{ color: "#555", fontSize: "16px" }}>
        Thank you for signing up! Please use the verification code below to complete your registration:
      </p>
      <div style={{ textAlign: "center", margin: "32px 0" }}>
        <span style={{
          display: "inline-block",
          background: "#f0f4ff",
          color: "#2d5be3",
          fontWeight: "bold",
          fontSize: "28px",
          letterSpacing: "6px",
          padding: "16px 32px",
          borderRadius: "6px",
          border: "1px solid #e0e7ff"
        }}>
          {code}
        </span>
      </div>
      <p style={{ color: "#888", fontSize: "14px" }}>
        If you did not request this, you can safely ignore this email.
      </p>
      <p style={{ color: "#888", fontSize: "14px", marginTop: "32px" }}>
        Best regards,<br />
        The Team
      </p>
    </div>
  </div>
);

export default CodeVerificationEmail;
