# ToolTag Deployment Guide

Production deployment guide for ToolTag on Vercel, Railway, or similar platforms.

---

## Prerequisites

Before deploying:

- ✅ PostgreSQL database (Neon, Supabase, Railway, etc.)
- ✅ Sentry account (optional but recommended)
- ✅ Git repository pushed to GitHub/GitLab

---

## Option 1: Deploy to Vercel (Recommended)

### 1. Database Setup

**Create PostgreSQL database** (choose one):

- **Neon** (recommended): https://neon.tech
  - Free tier: 0.5 GB storage, 1 GB transfer/month
  - Create project → copy connection string
- **Supabase**: https://supabase.com
  - Free tier: 500 MB database, 2 GB transfer/month
  - Project Settings → Database → Connection String (use "Transaction" pooling)
- **Railway**: https://railway.app
  - $5/month starter plan
  - New Project → PostgreSQL → copy DATABASE_URL

### 2. Deploy to Vercel

**A. Via CLI:**

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy from project root
cd apps/tooltag
vercel

# Follow prompts:
# - Link to existing project or create new
# - Set framework to SvelteKit
# - Root directory: apps/tooltag
```

**B. Via Dashboard:**

1. Visit https://vercel.com/new
2. Import your GitHub repository
3. Configure build settings:
   - **Framework Preset**: SvelteKit
   - **Root Directory**: `apps/tooltag`
   - **Build Command**: `pnpm build`
   - **Install Command**: `pnpm install`
4. Click "Deploy"

### 3. Environment Variables

In Vercel dashboard → Project Settings → Environment Variables, add:

```bash
# Required
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host/db
PUBLIC_APP_URL=https://your-app.vercel.app
AUTH_SECRET=<generate with: openssl rand -base64 32>

# Observability (recommended)
PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx

# Optional
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=noreply@tooltag.app
```

**Important**: Click "Add" for each variable, then redeploy.

### 4. Run Migrations

```bash
# Set DATABASE_URL locally (use production DB)
export DATABASE_URL=postgresql://...

# Run migrations
cd apps/tooltag
npx prisma migrate deploy

# Optional: Seed demo data (only for staging)
pnpm db:seed
```

### 5. Verify Deployment

- Visit `https://your-app.vercel.app`
- Test signup → create org → add item → scan QR
- Check Sentry for any errors

---

## Option 2: Deploy to Railway

### 1. Create New Project

1. Visit https://railway.app/new
2. Click "Deploy from GitHub repo"
3. Select your repository
4. Railway auto-detects pnpm monorepo

### 2. Add PostgreSQL Database

1. Click "+ New" → Database → PostgreSQL
2. Copy `DATABASE_URL` from Variables tab

### 3. Configure Service

In Railway dashboard → Service Settings:

**Root Directory**: `apps/tooltag`

**Build Command**:
```bash
cd ../.. && pnpm install && cd apps/tooltag && pnpm build
```

**Start Command**:
```bash
node build/index.js
```

**Environment Variables**: (same as Vercel above)

### 4. Deploy

- Click "Deploy"
- Railway auto-generates domain (e.g., `tooltag-production.up.railway.app`)
- Update `PUBLIC_APP_URL` to match

---

## Option 3: Self-Hosted (VPS/Docker)

### 1. Prerequisites

- Linux VPS (Ubuntu 22.04 recommended)
- Node.js 20+ and pnpm
- PostgreSQL 15+
- Nginx or Caddy for reverse proxy
- PM2 for process management

### 2. Setup

```bash
# Clone repo
git clone https://github.com/yourorg/tooltag.git
cd tooltag

# Install dependencies
pnpm install

# Create .env file
cd apps/tooltag
cp .env.example .env
nano .env  # Fill in production values

# Build
pnpm build

# Run migrations
npx prisma migrate deploy

# Start with PM2
pm2 start build/index.js --name tooltag
pm2 save
pm2 startup  # Follow instructions
```

### 3. Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/tooltag
server {
    listen 80;
    server_name tooltag.example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Enable site and restart
sudo ln -s /etc/nginx/sites-available/tooltag /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup SSL with Certbot
sudo certbot --nginx -d tooltag.example.com
```

---

## Post-Deployment Checklist

- [ ] Database migrations applied
- [ ] Environment variables set correctly
- [ ] Sentry error tracking active (check dashboard)
- [ ] QR codes generate and scan properly
- [ ] Email sending works (if configured)
- [ ] SSL certificate valid (HTTPS)
- [ ] Backups configured for database
- [ ] Domain DNS configured
- [ ] Auth cookies work (not blocked by CORS)

---

## Monitoring & Maintenance

### Error Tracking

- **Sentry Dashboard**: https://sentry.io/organizations/yourorg/issues/
- Set up alerts for critical errors
- Monitor performance metrics

### Database Backups

**Neon**: Automatic daily backups (7-day retention on free tier)

**Supabase**: Daily backups (7-day retention on free tier)

**Railway**:
```bash
# Manual backup
pg_dump $DATABASE_URL > backup-$(date +%Y%m%d).sql

# Restore
psql $DATABASE_URL < backup-20250930.sql
```

### Performance

- Monitor database query performance in Prisma Studio
- Enable Sentry performance monitoring (already configured)
- Check Vercel analytics for traffic patterns

### Updates

```bash
# Pull latest code
git pull origin main

# Install dependencies
pnpm install

# Run new migrations
npx prisma migrate deploy

# Rebuild and restart
pnpm build
pm2 restart tooltag  # If using PM2
# OR redeploy on Vercel/Railway
```

---

## Troubleshooting

### Build Fails on Vercel

**Error**: `Cannot find module '@tooltag/config'`

**Fix**: Ensure monorepo build includes workspace packages:
```json
// vercel.json (create in apps/tooltag)
{
  "buildCommand": "cd ../.. && pnpm install && cd apps/tooltag && pnpm build",
  "installCommand": "pnpm install"
}
```

### Database Connection Errors

**Error**: `Can't reach database server`

**Fix**:
- Check `DATABASE_URL` format: `postgresql://user:pass@host:port/db`
- For Neon: Use "pooled" connection string
- For Supabase: Use "Transaction" mode connection string
- Ensure database is publicly accessible (or use VPC if available)

### Auth Cookies Not Set

**Error**: Users can't stay logged in

**Fix**:
- Ensure `PUBLIC_APP_URL` matches deployment URL exactly
- Check SameSite cookie settings (may need adjustment for cross-domain)
- Verify HTTPS is enabled (cookies require secure context)

### QR Codes Don't Load

**Error**: QR images show broken icon

**Fix**:
- Check `/api/tags/[uid]/qr.svg` endpoint is accessible
- Ensure `PUBLIC_APP_URL` is set correctly (used in QR generation)
- Verify adapter is `@sveltejs/adapter-node` (not auto)

---

## Security Hardening

### Production Checklist

- [ ] `NODE_ENV=production` set
- [ ] `AUTH_SECRET` is cryptographically random (32+ chars)
- [ ] Database credentials rotated from defaults
- [ ] HTTPS enforced (redirect HTTP → HTTPS)
- [ ] CORS configured for API routes (if needed)
- [ ] Rate limiting enabled (via Vercel/Railway or Nginx)
- [ ] Prisma query logging disabled in production
- [ ] Sentry DSN kept secret (use env vars, not hardcoded)

### Rate Limiting (Nginx Example)

```nginx
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

location /api/auth/ {
    limit_req zone=auth burst=10 nodelay;
    proxy_pass http://localhost:3000;
}
```

---

## Cost Estimates

### Free Tier (Hobby Projects)

- **Vercel**: Free (hobby tier)
- **Neon**: Free (0.5 GB database)
- **Sentry**: Free (5k errors/month)
- **Total**: $0/month

### Production (Small Team)

- **Vercel Pro**: $20/month
- **Neon Scale**: $19/month (3 GB)
- **Sentry Team**: $26/month (50k errors)
- **Total**: ~$65/month

### High Volume (1000+ users)

- **Vercel Pro**: $20/month
- **Railway**: $10-50/month (usage-based)
- **Supabase Pro**: $25/month
- **Sentry Business**: $80/month
- **Total**: ~$135-185/month

---

## Next Steps

After deployment:

1. **Test golden path**: Signup → Create org → Add item → Generate QR → Scan → Check-out → Check-in
2. **Monitor Sentry** for first 24 hours to catch any production-only errors
3. **Set up alerts** (Sentry, Vercel, database)
4. **Configure backups** (daily database snapshots)
5. **Share with users** 🚀

---

## Support

- **Issues**: https://github.com/yourorg/tooltag/issues
- **Documentation**: README.md
- **Phase Summaries**: PHASE_*.md files

**Questions?** Open an issue or check the phase summaries for implementation details.
