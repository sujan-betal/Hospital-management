import type { NextConfig } from "next";

// Backend origin used by the /api/* proxy. In development the local FastAPI
// server is used; on Vercel set BACKEND_URL to the Render service URL.
const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:8000";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${BACKEND_URL}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
