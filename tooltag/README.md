# ToolTag

> QR-powered tool & equipment tracking app for teams

**Status**: Production Ready ✅
**Version**: 1.0.0-MVP
**Tech Stack**: SvelteKit 2 + TypeScript + PostgreSQL + Prisma

---

## Overview

ToolTag is a complete equipment tracking solution built for teams that need to manage tools, track check-outs, and maintain accountability. Scan QR codes with any mobile device to instantly check items out or in — no app installation required.

### Key Features

- ✅ **Multi-tenant Organizations** with role-based access control (OWNER/MANAGER/TECH)
- ✅ **Inventory Management** with locations, categories, and full CRUD
- ✅ **QR Code System** with public scan pages (no login required)
- ✅ **Check-Out/In Workflow** with due dates, notes, and status tracking
- ✅ **Audit Logging** with CSV export and detailed activity timeline
- ✅ **Dashboard Metrics** showing real-time inventory and assignment stats
- ✅ **Production Ready** with E2E tests, error tracking, and deployment guide

---

## Quick Start

### Prerequisites

- **Node.js** 20+ and **pnpm** 9+
- **PostgreSQL** database (local via Docker or cloud via Neon/Supabase)

### 1. Clone & Install

```bash
git clone https://github.com/yourorg/tooltag.git
cd tooltag
pnpm install
```

### 2. Database Setup

**Option A: Local PostgreSQL with Docker**
```bash
docker run --name tooltag-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -d postgres
```

**Option B: Cloud Database**
- [Neon](https://neon.tech) (recommended, free tier)
- [Supabase](https://supabase.com) (free tier)
- Copy connection string from dashboard

### 3. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values
# Required:
#   DATABASE_URL=postgresql://...
#   AUTH_SECRET=<run: openssl rand -base64 32>
#   PUBLIC_APP_URL=http://localhost:5173
```

### 4. Database Migration

```bash
cd apps/tooltag

# Generate Prisma client
npx prisma generate

# Run migrations
pnpm db:migrate

# Seed demo data (optional)
pnpm db:seed
```

### 5. Start Development Server

```bash
# From project root
pnpm dev

# Or from apps/tooltag
cd apps/tooltag
pnpm dev
```

App will be available at: **http://localhost:5173**

**Demo credentials**: `demo@tooltag.app` / `password123`

---

## Usage

### First-Time Setup

1. **Sign Up**: Create your account at `/signup`
2. **Create Organization**: Set organization name and URL slug
3. **Add Locations & Categories**: Visit Settings to organize inventory
4. **Create Items**: Add tools/equipment with SKU, serial numbers, photos
5. **Generate QR Tags**: Click "Generate QR Tag" on any item
6. **Print Tags**: Use the print view to create physical labels

### Daily Workflow

1. **Scan QR Code**: Use phone camera or visit `/scan` page
2. **Check Out Item**: Select user, set due date, add notes
3. **Check In Item**: Scan again when returned, add return notes
4. **View Activity**: Check audit log for complete history

### Team Management

- **Invite Members**: Settings → Team → Add member email
- **Assign Roles**:
  - **OWNER**: Full access (billing, delete org)
  - **MANAGER**: Manage inventory, team, check-outs
  - **TECH**: View inventory, check-out/in items

---

## Project Structure

```
tooltag/
├── apps/
│   └── tooltag/              # Main SvelteKit app
│       ├── src/
│       │   ├── lib/          # Shared utilities
│       │   │   └── server/   # Server-only code
│       │   │       ├── auth/ # Session, password, RBAC
│       │   │       └── db.ts # Prisma client
│       │   └── routes/       # Pages & API routes
│       │       ├── (auth)/   # Login/signup pages
│       │       ├── api/      # REST API endpoints
│       │       ├── dashboard/# Protected dashboard
│       │       ├── scan/     # Public QR scan pages
│       │       └── print/    # Printable tag sheets
│       ├── prisma/
│       │   ├── schema.prisma # Database schema (11 models)
│       │   └── seed.ts       # Demo data seeder
│       └── tests/
│           └── e2e/          # Playwright E2E tests
├── packages/
│   └── config/               # Shared configs & env schema
└── DEPLOYMENT.md             # Production deployment guide
```

---

## Available Scripts

### Development

```bash
pnpm dev              # Start dev server (localhost:5173)
pnpm build            # Build for production
pnpm preview          # Preview production build
pnpm type-check       # TypeScript validation
pnpm lint             # Run ESLint
pnpm format           # Run Prettier
```

### Database

```bash
pnpm db:migrate       # Run migrations
pnpm db:push          # Push schema without migration (dev only)
pnpm db:seed          # Seed demo data
pnpm db:studio        # Open Prisma Studio GUI
```

### Testing

```bash
pnpm test             # Run E2E tests (Playwright)
pnpm test:unit        # Run unit tests (Vitest)
npx playwright test --ui  # Interactive test mode
```

---

## Deployment

See **[DEPLOYMENT.md](./DEPLOYMENT.md)** for comprehensive production deployment guide covering:

- ✅ Vercel (recommended, one-click deploy)
- ✅ Railway (container-based)
- ✅ Self-hosted VPS (Docker + Nginx)
- ✅ Database setup (Neon, Supabase, Railway)
- ✅ Environment variables
- ✅ SSL/HTTPS configuration
- ✅ Monitoring and backups

### Quick Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/yourorg/tooltag)

**Post-Deploy**: Set environment variables in Vercel dashboard, then run migrations:

```bash
# Set DATABASE_URL locally to production DB
export DATABASE_URL=postgresql://...
npx prisma migrate deploy
```

---

## Tech Stack

- **Framework**: SvelteKit 2 + TypeScript
- **Database**: PostgreSQL + Prisma ORM
- **Styling**: Tailwind CSS
- **Validation**: Zod
- **Auth**: Cookie-based sessions with bcrypt
- **QR Codes**: Server-side SVG generation
- **Testing**: Playwright (E2E) + Vitest (unit)
- **Error Tracking**: Sentry
- **Deployment**: Vercel/Railway/VPS ready

---

## Development Phases

All phases complete — **production ready** ✅

### Phase 0: Foundation ✅

**Status**: Complete

- ✅ Monorepo structure (pnpm workspaces)
- ✅ Shared configuration (TypeScript, ESLint, Prettier, Zod)
- ✅ Complete Prisma schema (11 models)
- ✅ Seed script with demo data
- ✅ Tailwind CSS setup

See `README.md` for quick start guide.

### Phase 1: Auth & Org Management ✅

**Status**: Complete (8.5 hours)
- ✅ Authentication routes (signup/login/logout)
- ✅ Organization CRUD + membership
- ✅ RBAC middleware (3 roles: OWNER, MANAGER, TECH)
- ✅ User dashboard + settings UI
- ✅ Team management (role changes, member removal)

See `PHASE_1_SUMMARY.md` for details.

### Phase 2: Core Inventory ✅

**Status**: Complete (6 hours)
- ✅ Item/Location/Category CRUD (15 API endpoints)
- ✅ Inventory list with search/filters/pagination
- ✅ CSV import/export functionality
- ✅ Item detail and edit pages

See `PHASE_2_SUMMARY.md` for details.

### Phase 3: QR Tag System ✅

**Status**: Complete (5.5 hours)
- ✅ Server-side QR SVG generation (nanoid UIDs)
- ✅ Tag creation for items (generate/delete)
- ✅ Printable tag sheets (one per page)
- ✅ Mobile scan route + camera wrapper
- ✅ Public scan landing page with item details

See `PHASE_3_SUMMARY.md` for details.

### Phase 4: Check-Out/In Workflow ✅

**Status**: Complete (6 hours)
- ✅ Assignment CRUD APIs (4 endpoints with transactions)
- ✅ Check-out form (user select, due date, notes)
- ✅ Check-in form (return notes, overdue warnings)
- ✅ Item status updates (AVAILABLE ↔ CHECKED_OUT)
- ✅ Mobile quick actions from scan page
- ✅ Assignments dashboard with filters

See `PHASE_4_SUMMARY.md` for details.

### Phase 5: Audit Log & Reporting ✅

**Status**: Complete (3.5 hours)
- ✅ Audit log list page with filters (action, entity, date)
- ✅ Activity timeline view (sorted DESC)
- ✅ Dashboard metrics (items, assignments, members)
- ✅ Audit log CSV export

See `PHASE_5_SUMMARY.md` for details.

### Phase 6: Shared Packages (SKIPPED)

**Decision**: Defer to post-MVP refactor
- Not critical for launch
- `packages/ui` and `packages/sdk` can wait

### Phase 7: Testing & Observability ✅

**Status**: Complete (2.5 hours)
- ✅ Playwright E2E test (golden path: signup → checkin)
- ✅ Sentry error tracking (client + server)
- ✅ Production environment configuration
- ✅ Deployment guide (Vercel, Railway, VPS)

See `PHASE_7_SUMMARY.md` for details.

### Phase 8: Deploy & Polish ✅

**Status**: Complete
- ✅ Production-ready README with usage guide
- ✅ Health check endpoint for monitoring
- ✅ Final documentation review
- ✅ Project summary and handoff

See `PHASE_8_SUMMARY.md` for details.

---

## API Documentation

**Base URL**: `/api/organizations/[orgId]`

### Authentication
- `POST /api/auth/signup` - Create account
- `POST /api/auth/login` - Sign in
- `POST /api/auth/logout` - Sign out

### Organizations
- `GET /api/organizations` - List user's orgs
- `POST /api/organizations` - Create org
- `PATCH /api/organizations/[orgId]` - Update org
- `DELETE /api/organizations/[orgId]` - Delete org

### Inventory
- `GET /api/organizations/[orgId]/items` - List items (with filters)
- `POST /api/organizations/[orgId]/items` - Create item
- `GET /api/organizations/[orgId]/items/[itemId]` - Get item
- `PATCH /api/organizations/[orgId]/items/[itemId]` - Update item
- `DELETE /api/organizations/[orgId]/items/[itemId]` - Delete item
- `POST /api/organizations/[orgId]/items/import` - CSV import
- `GET /api/organizations/[orgId]/items/export` - CSV export

### QR Tags
- `POST /api/organizations/[orgId]/items/[itemId]/tags` - Generate tag
- `DELETE /api/organizations/[orgId]/items/[itemId]/tags/[uid]` - Delete tag
- `GET /api/tags/[uid]` - Resolve tag (public)
- `GET /api/tags/[uid]/qr.svg` - Get QR code (public)

### Assignments
- `GET /api/organizations/[orgId]/assignments` - List assignments
- `POST /api/organizations/[orgId]/assignments` - Check out
- `GET /api/organizations/[orgId]/assignments/[id]` - Get assignment
- `PATCH /api/organizations/[orgId]/assignments/[id]` - Check in

### Audit & Metrics
- `GET /api/organizations/[orgId]/audit` - List audit logs
- `GET /api/organizations/[orgId]/audit/export` - Export CSV
- `GET /api/organizations/[orgId]/metrics` - Dashboard metrics

### Health
- `GET /api/health` - Health check (uptime, DB status)

**Full API docs**: See phase summary files for detailed schemas.

---

## Contributing

### Development Workflow

1. Fork repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Code Standards

- TypeScript strict mode enabled
- ESLint + Prettier for formatting
- Server-side RBAC checks on all protected routes
- Zod validation for all API inputs
- E2E tests for critical paths

### Testing

```bash
# Run E2E tests before committing
pnpm test

# Check TypeScript
pnpm type-check

# Format code
pnpm format
```

---

## Support & Documentation

- **Getting Started**: See Quick Start section above
- **Deployment**: See [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Phase Summaries**: See `PHASE_*.md` files for implementation details
- **Issues**: [GitHub Issues](https://github.com/yourorg/tooltag/issues)

---

## Roadmap

**Post-MVP Enhancements:**

- [ ] Email notifications (overdue items, assignments)
- [ ] Mobile app (React Native or Flutter)
- [ ] Barcode scanning (in addition to QR)
- [ ] Maintenance scheduling
- [ ] Low stock alerts
- [ ] Multi-location transfers
- [ ] Advanced reporting (Charts.js, export to Excel)
- [ ] Stripe billing integration
- [ ] API webhooks for integrations
- [ ] Two-factor authentication (2FA)

---

## License

MIT License - see [LICENSE](./LICENSE) file for details.

---

## Acknowledgments

Built with ❤️ using:
- [SvelteKit](https://kit.svelte.dev/)
- [Prisma](https://www.prisma.io/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Playwright](https://playwright.dev/)
- [Sentry](https://sentry.io/)
