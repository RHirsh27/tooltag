# 🚀 ToolTag - Vercel Deployment Guide

**Quick deployment guide for launching ToolTag on Vercel**

---

## 📋 Prerequisites

Before deploying:
- ✅ Vercel account (free tier available at https://vercel.com)
- ✅ Database ready (Neon recommended - see below)
- ✅ Code committed to Git (optional but recommended)

---

## Step 1: Create Production Database (5 minutes)

### Option A: Neon (Recommended - Free Tier)

1. **Sign up**: Visit https://neon.tech
2. **Create project**: Click "New Project"
3. **Configure**:
   - Name: `tooltag-production`
   - Region: Choose closest to your users
   - Postgres Version: 16 (default)
4. **Copy connection string**:
   - Go to Dashboard → Connection Details
   - Copy the connection string (starts with `postgresql://`)
   - **Save this** - you'll need it for Vercel

**Example connection string:**
```
postgresql://username:password@ep-cool-name.us-east-2.aws.neon.tech/neondb?sslmode=require
```

### Option B: Supabase (Alternative - Free Tier)

1. Visit https://supabase.com
2. Create new project
3. Go to Settings → Database
4. Copy connection string (use "Transaction" pooling mode)

---

## Step 2: Deploy to Vercel

### Method A: Via CLI (Recommended)

**1. Login to Vercel:**
```bash
vercel login
# Press ENTER to open browser
# Authenticate in browser
# Return to terminal
```

**2. Deploy:**
```bash
# From project root
cd apps/tooltag
vercel

# You'll be asked:
# - Set up and deploy? [Y/n] → Y
# - Which scope? → Select your account
# - Link to existing project? [y/N] → N
# - What's your project's name? → tooltag (or custom name)
# - In which directory is your code located? → ./
# - Want to override settings? [y/N] → N
```

**3. Wait for deployment:**
```
✓ Deployment ready
https://tooltag-xxxx.vercel.app
```

### Method B: Via Vercel Dashboard (Alternative)

1. **Visit**: https://vercel.com/new
2. **Import Git Repository**:
   - Connect GitHub/GitLab account
   - Select your ToolTag repository
   - Or upload folder manually
3. **Configure Build Settings**:
   - Framework Preset: **SvelteKit**
   - Root Directory: `apps/tooltag`
   - Build Command: `pnpm build`
   - Output Directory: `.svelte-kit/output` (auto-detected)
   - Install Command: `pnpm install`
4. **Click "Deploy"**

---

## Step 3: Configure Environment Variables

**In Vercel Dashboard:**
1. Go to your project → Settings → Environment Variables
2. Add the following:

### Required Variables:

```bash
# Node Environment
NODE_ENV=production

# Database (from Neon/Supabase)
DATABASE_URL=postgresql://username:password@host/database?sslmode=require

# App URL (Vercel will give you this after first deploy)
PUBLIC_APP_URL=https://your-project.vercel.app

# Auth Secret (IMPORTANT - generate new one!)
# Generate with: openssl rand -base64 32
AUTH_SECRET=YOUR_GENERATED_SECRET_HERE_MIN_32_CHARS

# Storage (Vercel serverless - use default for now)
STORAGE_TYPE=local
STORAGE_PATH=/tmp/uploads
```

### Optional Variables:

```bash
# Email (if you want notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=noreply@tooltag.app

# Error Tracking (recommended)
PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx

# Cron Jobs
CRON_SECRET=YOUR_GENERATED_CRON_SECRET
```

**Important**: After adding variables, click "Redeploy" in Vercel dashboard!

---

## Step 4: Run Database Migrations

**From your local machine:**

```bash
# Set DATABASE_URL to production database
$env:DATABASE_URL="postgresql://username:password@host/database?sslmode=require"

# Navigate to app directory
cd apps/tooltag

# Run migrations
npx prisma migrate deploy

# Optional: Seed demo data (for testing)
pnpm db:seed
```

---

## Step 5: Verify Deployment

**Test your production app:**

1. **Visit your app**: https://your-project.vercel.app
2. **Sign up**: Create a new account
3. **Create organization**: Set up your first org
4. **Add location**: Test the settings
5. **Create item**: With photo upload
6. **Generate QR tag**: Test QR generation
7. **Scan tag**: Test camera scanning (requires HTTPS - works on Vercel!)
8. **Check out item**: Test the workflow
9. **View dashboard**: Check metrics load

**Health Check:**
```bash
curl https://your-project.vercel.app/api/health
# Should return: {"status":"healthy",...}
```

---

## 🎯 Quick Reference Commands

### Deploy Updates:
```bash
# After making code changes
cd apps/tooltag
vercel --prod
```

### View Logs:
```bash
vercel logs
# Or visit: Vercel Dashboard → Your Project → Logs
```

### Environment Variables:
```bash
# List all env vars
vercel env ls

# Add new env var
vercel env add VARIABLE_NAME

# Remove env var
vercel env rm VARIABLE_NAME
```

---

## ⚡ Vercel-Specific Configuration

### For Better Performance on Vercel:

**1. Create `vercel.json` in `apps/tooltag/`:**
```json
{
  "buildCommand": "pnpm build",
  "devCommand": "pnpm dev",
  "installCommand": "pnpm install",
  "framework": "sveltekit",
  "outputDirectory": ".svelte-kit/output",
  "regions": ["iad1"],
  "crons": [{
    "path": "/api/tasks/send-overdue-reminders",
    "schedule": "0 9 * * *"
  }]
}
```

**2. Update to Vercel Adapter (Optional but Recommended):**
```bash
pnpm add -D @sveltejs/adapter-vercel
```

Then update `svelte.config.js`:
```javascript
import adapter from '@sveltejs/adapter-vercel';

const config = {
  kit: {
    adapter: adapter({
      runtime: 'nodejs20.x'
    })
  }
};
```

**3. For File Uploads on Vercel:**

Vercel serverless functions use `/tmp` which is ephemeral. For permanent storage:

**Option A: Vercel Blob Storage**
```bash
pnpm add @vercel/blob
```

**Option B: AWS S3** (update `src/lib/server/storage.ts`)

**Option C: External Image Host** (Cloudinary, Imgur)

For MVP, `/tmp` storage works but files disappear between deployments.

---

## 🐛 Common Issues & Solutions

### Issue: "Database connection failed"
**Solution**: Check DATABASE_URL has `?sslmode=require` at the end

### Issue: "Auth secret too short"
**Solution**: Generate new secret with `openssl rand -base64 32`

### Issue: "Build failed - can't find @tooltag/config"
**Solution**: 
- Ensure monorepo structure is correct
- Vercel should install from workspace root
- Root Directory should be `apps/tooltag`

### Issue: "Photos not persisting"
**Solution**: 
- This is expected on Vercel (serverless)
- Switch to Vercel Blob or S3 for permanent storage
- Or use external image hosting service

### Issue: "Emails not sending"
**Solution**: 
- Check SMTP credentials in Vercel environment variables
- Use Gmail App Password (not regular password)
- Check Vercel logs for email errors

---

## 📊 Vercel Free Tier Limits

**Good for:**
- ✅ Hobby projects
- ✅ MVPs and startups
- ✅ Testing and staging
- ✅ Small teams (<100 users)

**Limits:**
- 100 GB bandwidth/month
- 6,000 build minutes/month
- 100 GB-hours serverless function execution
- 12 serverless functions max
- Free custom domain
- Free SSL certificates

**When to upgrade to Pro ($20/month):**
- More than 1 TB bandwidth
- Need password protection
- Want analytics
- Need team collaboration
- Priority support

---

## 🎉 You're Ready!

**When you're ready to deploy:**

1. **Ensure you have**:
   - [ ] Vercel account created
   - [ ] Production database URL (from Neon)
   - [ ] Auth secret generated
   - [ ] Code working locally

2. **Run these commands**:
   ```bash
   cd apps/tooltag
   vercel login
   vercel
   ```

3. **Configure environment variables** in Vercel dashboard

4. **Run migrations**:
   ```bash
   $env:DATABASE_URL="your-production-url"
   npx prisma migrate deploy
   ```

5. **Visit your app**: https://your-project.vercel.app

**Deployment time: 15-20 minutes total** ⚡

---

**Need help?** Check `DEPLOYMENT.md` for detailed troubleshooting or visit Vercel docs at https://vercel.com/docs

