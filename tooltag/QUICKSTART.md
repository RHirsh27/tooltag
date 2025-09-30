# ToolTag — 10-Minute Quick Start

Get ToolTag running locally in under 10 minutes.

---

## Prerequisites (2 min)

1. **Node.js 20+** — [Download](https://nodejs.org/)
2. **pnpm 9+** — Install: `npm install -g pnpm`
3. **PostgreSQL** — Choose one:
   - **Docker** (easiest): `docker run --name tooltag-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres`
   - **Cloud** (free): [Neon](https://neon.tech) or [Supabase](https://supabase.com)

---

## Setup Steps (8 min)

### 1. Clone & Install (2 min)

```bash
cd tooltag
pnpm install
```

### 2. Configure Database (1 min)

**If using Docker Postgres (from Prerequisites):**
```bash
# .env is already configured for localhost:5432
# Default: postgresql://postgres:postgres@localhost:5432/tooltag
```

**If using cloud database:**
```bash
# Edit .env and replace DATABASE_URL with your connection string
# Example for Neon:
DATABASE_URL=postgresql://user:password@ep-cool-name-123456.us-east-2.aws.neon.tech/tooltag
```

### 3. Initialize Database (3 min)

```bash
cd apps/tooltag

# Generate Prisma Client
npx prisma generate

# Create database & tables
pnpm db:migrate

# Seed demo data
pnpm db:seed
```

**Expected output:**
```
✅ Seeding complete:
   Users: 1
   Organizations: 1
   Items: 2
   Tags: 2

📧 Demo login: demo@tooltag.app / password123
```

### 4. Start App (1 min)

```bash
# From root directory
cd ../..
pnpm dev
```

**Open:** http://localhost:5173

You should see the default SvelteKit welcome page.

---

## Verification (1 min)

```bash
# Open Prisma Studio to browse data
cd apps/tooltag
pnpm db:studio
```

Should show:
- 1 User (demo@tooltag.app)
- 1 Organization (Demo Organization)
- 2 Items (Cordless Drill, Claw Hammer)
- 2 Tags (with nanoid UIDs)

---

## Troubleshooting

### "Can't reach database server"
- **Docker users**: Check container is running: `docker ps`
- **Cloud users**: Verify connection string in `.env`

### "Port 5432 already in use"
- Another Postgres instance is running
- **Fix**: Stop other Postgres or change port in `.env`

### "Prisma Client not generated"
```bash
cd apps/tooltag
npx prisma generate
```

### Build errors after changing schema
```bash
cd apps/tooltag
pnpm db:push  # Push changes without migration
npx prisma generate
```

---

## What's Next?

**Phase 0 is complete!** You now have:
- ✅ Full database schema (11 models)
- ✅ Demo data to work with
- ✅ Dev environment running

**Ready for Phase 1:**
- Authentication routes (signup/login)
- Organization management
- User dashboard

---

## Useful Commands

```bash
# Development
pnpm dev                    # Start dev server (port 5173)

# Database
pnpm db:migrate             # Create new migration
pnpm db:push                # Sync schema without migration (dev only)
pnpm db:seed                # Re-seed demo data
pnpm db:studio              # Open database GUI

# Reset everything
cd apps/tooltag
npx prisma migrate reset    # Deletes DB, re-runs all migrations + seed
```

---

## Project Structure

```
tooltag/
├── apps/tooltag/           # Main SvelteKit app
│   ├── src/
│   │   ├── lib/            # Utilities (auth, db, etc.)
│   │   └── routes/         # Pages + API routes
│   └── prisma/
│       ├── schema.prisma   # Database models
│       └── seed.ts         # Demo data
├── packages/
│   └── config/             # Shared env + TypeScript configs
└── .env                    # Your local config
```

---

**Ready to build!** 🚀

For detailed Phase 0 summary: see `PHASE_0_SUMMARY.md`
