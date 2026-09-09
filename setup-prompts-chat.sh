#!/usr/bin/env bash
# Finishes setting up prompts.chat (self-hosted).
# Run this from your normal Mac Terminal (NOT inside Claude) so it has real internet access.
#
# What this does:
#   1. Clones github.com/f/prompts.chat into ~/Desktop/my project/prompts-chat
#   2. Writes .env (already pointed at a live Neon Postgres database)
#   3. Writes prompts.config.ts (email/password auth, sensible defaults)
#   4. npm install, then generates the Prisma client, runs migrations, and seeds prompts
#   5. Starts the dev server at http://localhost:3000
#
# Safe to re-run: git clone is skipped if the folder already exists.

set -euo pipefail

TARGET_DIR="$HOME/Desktop/my project/prompts-chat"

echo "==> Node/npm versions:"
node -v || { echo "Node.js not found. Install Node 24.x first: https://nodejs.org"; exit 1; }
npm -v

if [ -d "$TARGET_DIR/.git" ]; then
  echo "==> Repo already cloned at $TARGET_DIR, skipping clone"
else
  echo "==> Cloning prompts.chat..."
  mkdir -p "$HOME/Desktop/my project"
  git clone https://github.com/f/prompts.chat.git "$TARGET_DIR"
fi

cd "$TARGET_DIR"

echo "==> Writing .env"
cat > .env <<'ENV_EOF'
# Generated for this self-hosted deploy
# prompts.chat environment configuration

# Database (Neon Postgres project "prompts-chat")
DATABASE_URL="postgresql://neondb_owner:npg_XPu0OZlbk5Nz@ep-shiny-math-aeoe3vdp-pooler.c-2.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require"
DIRECT_URL="postgresql://neondb_owner:npg_XPu0OZlbk5Nz@ep-shiny-math-aeoe3vdp.c-2.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require"

# Authentication
AUTH_SECRET="iMNkhEFnIWhiyoQW2nHUIJgU6+uf9gpW6HjooS+1jSE="
AUTH_URL="http://localhost:3000"
AUTH_TRUST_HOST=true

# Cron Job Secret
CRON_SECRET="8f31db025ae10d531025f6cdf54978af"
ENV_EOF

echo "==> Writing prompts.config.ts"
cat > prompts.config.ts <<'CONFIG_EOF'
import { defineConfig } from "@/lib/config";

// Private clone configuration
const useCloneBranding = true;

export default defineConfig({
  // Branding - your organization's identity
  branding: {
    name: "My Prompt Library",
    logo: "/logo.svg",
    logoDark: "/logo.svg",
    favicon: "/logo.svg",
    description: "Collect, organize, and share AI prompts",
  },

  // Theme - design system configuration
  theme: {
    radius: "sm",
    variant: "default",
    density: "default",
    colors: {
      primary: "#6366f1",
    },
  },

  // Authentication plugins
  auth: {
    providers: ["credentials"],
    allowRegistration: true,
  },

  // Internationalization
  i18n: {
    locales: ["en"],
    defaultLocale: "en",
  },

  // Features
  features: {
    privatePrompts: true,
    changeRequests: true,
    categories: true,
    tags: true,
    comments: true,
    aiSearch: false,
    aiGeneration: false,
    mcp: false,
  },

  // Homepage customization (clone branding mode)
  homepage: {
    useCloneBranding,
    achievements: {
      enabled: false,
    },
    sponsors: {
      enabled: false,
      items: [],
    },
  },
});
CONFIG_EOF

echo "==> Installing dependencies (this can take a few minutes)..."
npm install

echo "==> Setting up the database (prisma generate + migrate + seed)..."
npm run db:setup

echo "==> All set. Starting the dev server..."
echo "    Open http://localhost:3000 once it's ready. Press Ctrl+C to stop it."
npm run dev
