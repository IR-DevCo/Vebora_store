module.exports = {};/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  compiler: {
    // پشتیبانی از TailwindCSS و سایر کتابخانه‌ها
    styledComponents: true,
  },
  env: {
    NEXT_PUBLIC_BACKEND_URL: process.env.NEXT_PUBLIC_BACKEND_URL || "http://127.0.0.1:8000",
    NEXT_PUBLIC_FORCE_CHANNEL: process.env.NEXT_PUBLIC_FORCE_CHANNEL || "YourChannelUsername",
    NEXT_PUBLIC_BOT_NAME: process.env.NEXT_PUBLIC_BOT_NAME || "Vebora Store",
  },
  images: {
    domains: ["via.placeholder.com"], // اضافه کردن دامین‌ها در صورت لود تصویر خارجی
  },
  async rewrites() {
    return [
      // می‌توانید مسیرهای API را مستقیماً به Backend ریدایرکت کنید
      {
        source: "/api/:path*",
        destination: `${process.env.NEXT_PUBLIC_BACKEND_URL}/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;
