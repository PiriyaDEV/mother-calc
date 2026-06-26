import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "promptpay.io",
      },
    ],
  },
};

export default nextConfig;
