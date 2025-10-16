# Base-OSS-MVP

We will match OSS contributors with relevant OSS projects in the ecosystem.

To make things happen, we will work directly with Base / Coinbase core team, especially on the following repo:

- AgentKit
- 0x402
- OnchainKit
- Repos from builders from Base (after fill in a form)

**Deliverables**: one app and a mini-app (or directly a mini-app)


## Getting Started Frontend 

This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Pure On-Chain Storage (Structure)

### How Data Flows
User Action (Frontend)
    ↓
Sign Transaction (Privy Wallet)
    ↓
Smart Contract on Base (Data Storage)
    ↓
Read Back from Contract (Display in UI)


Built for Base Ecosystem 🔵
