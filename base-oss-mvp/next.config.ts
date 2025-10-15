// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Tell Next.js where to find public assets
  publicRuntimeConfig: {
    staticFolder: '/src/public',
  },
}

module.exports = nextConfig