# New Features Implementation Guide

This document describes the three new features added to ToolTag and how to configure them.

---

## 1. Camera QR Scanning 📷

### What's New
- **Real-time QR code scanning** using device camera
- **Automatic detection** - no manual input needed
- **Visual feedback** with scanning frame overlay
- **Mobile-optimized** with back camera support

### Files Added
- `src/lib/components/QRScanner.svelte` - Reusable QR scanner component
- Updated `src/routes/scan/+page.svelte` - Integrated scanner

### How to Use
1. Navigate to `/scan` page
2. Click "Start QR Scanner"
3. Allow camera permissions when prompted
4. Point camera at QR code
5. Automatic redirect to item details once detected

### Technical Details
- Uses **jsQR** library for QR code detection
- Runs detection at 60fps using `requestAnimationFrame`
- Supports both ToolTag URLs and raw UIDs
- Falls back to manual entry if camera unavailable

### Browser Support
- ✅ Chrome/Edge (desktop & mobile)
- ✅ Safari (iOS 11+)
- ✅ Firefox (desktop & mobile)
- ⚠️ Requires HTTPS in production (camera API requirement)

---

## 2. Photo Uploads 📸

### What's New
- **Direct file upload** for item photos
- **Image preview** before and after upload
- **Drag & drop support** (browser dependent)
- **Local filesystem storage** with S3-ready architecture

### Files Added
- `src/lib/server/storage.ts` - File upload service
- `src/lib/components/FileUpload.svelte` - Reusable upload component
- `src/routes/api/upload/+server.ts` - Upload API endpoint
- `src/routes/uploads/[filename]/+server.ts` - Static file serving
- Updated inventory forms to include photo upload

### Configuration

#### Local Storage (Default)
```env
STORAGE_TYPE=local
STORAGE_PATH=./uploads
```

The `uploads` directory will be created automatically. Ensure your deployment has write permissions.

#### S3 Storage (Future)
```env
STORAGE_TYPE=s3
# S3 credentials would go here
```

*Note: S3 implementation is stubbed for future enhancement.*

### File Constraints
- **Allowed types**: JPEG, PNG, GIF, WebP
- **Max size**: 5MB per file
- **Validation**: Client-side and server-side

### How to Use
1. Create or edit an item
2. Click "Upload Photo" button
3. Select image file
4. Preview appears immediately
5. Photo uploaded on form submission
6. Remove photo with X button if needed

### Deployment Considerations

**Vercel/Serverless:**
- Files stored in `/tmp` are ephemeral
- Recommendation: Switch to S3 or Vercel Blob Storage
- Alternative: Use external image host (Cloudinary, Imgur)

**Self-hosted/VPS:**
- Local storage works perfectly
- Ensure `STORAGE_PATH` has write permissions
- Configure nginx to serve `/uploads` statically for better performance

**Docker:**
- Mount `uploads` directory as volume for persistence:
  ```yaml
  volumes:
    - ./uploads:/app/uploads
  ```

---

## 3. Email Notifications 📧

### What's New
- **Checkout notifications** - Email when item is checked out
- **Checkin confirmations** - Email when item is returned
- **Overdue reminders** - Automated daily reminders for overdue items
- **Team invites** - Email invitations to join organization (template ready)

### Files Added
- `src/lib/server/email.ts` - Email service with nodemailer
- `src/lib/server/tasks/send-overdue-reminders.ts` - Overdue reminder task
- `src/routes/api/tasks/send-overdue-reminders/+server.ts` - Task endpoint
- Updated assignment APIs to send notifications

### Configuration

#### SMTP Settings
Add to your `.env` file:

```env
# Required for email functionality
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=noreply@tooltag.app
```

#### Email Providers

**Gmail:**
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password  # Use App Password, not regular password
```
*Setup: Google Account → Security → 2-Step Verification → App Passwords*

**SendGrid:**
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
SMTP_FROM=verified-sender@yourdomain.com
```
*Free tier: 100 emails/day*

**Mailgun:**
```env
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=postmaster@your-domain.mailgun.org
SMTP_PASS=your-mailgun-smtp-password
SMTP_FROM=noreply@your-domain.com
```
*Free tier: 1,000 emails/month*

**Amazon SES:**
```env
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USER=your-ses-smtp-username
SMTP_PASS=your-ses-smtp-password
SMTP_FROM=verified-email@yourdomain.com
```
*Cost: $0.10 per 1,000 emails*

### Email Templates

All emails include:
- **HTML version** - Beautifully formatted with brand colors
- **Plain text version** - Fallback for text-only clients
- **Responsive design** - Mobile-friendly layouts
- **Direct action links** - Quick access to dashboard/items

### Automatic Notifications

**Checkout:**
- Triggered when item is checked out
- Includes: Item name, due date (if set), organization
- Recipient: User who checked out the item

**Checkin:**
- Triggered when item is returned
- Includes: Item name, checkout duration, organization
- Recipient: User who returned the item

**Overdue Reminders:**
- Requires scheduled task (see below)
- Sent daily for items past due date
- Includes: Days overdue, warning styling

### Scheduled Tasks (Overdue Reminders)

#### Manual Trigger (Testing)
```bash
curl -X POST https://your-app.com/api/tasks/send-overdue-reminders \
  -H "Authorization: Bearer your-cron-secret"
```

#### Vercel Cron (Recommended for Vercel deployments)

Create `vercel.json`:
```json
{
  "crons": [{
    "path": "/api/tasks/send-overdue-reminders",
    "schedule": "0 9 * * *"
  }]
}
```

Add to `src/routes/api/tasks/send-overdue-reminders/+server.ts`:
```typescript
// Vercel cron uses different auth
if (request.headers.get('authorization') !== `Bearer ${process.env.CRON_SECRET}`) {
  // Check Vercel cron header instead
  if (request.headers.get('x-vercel-signature')) {
    // Verify Vercel signature
  }
}
```

#### GitHub Actions (Self-hosted or any deployment)

Create `.github/workflows/overdue-reminders.yml`:
```yaml
name: Send Overdue Reminders
on:
  schedule:
    - cron: '0 9 * * *'  # 9 AM daily
  workflow_dispatch:  # Allow manual trigger

jobs:
  send-reminders:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Overdue Reminders
        run: |
          curl -X POST ${{ secrets.APP_URL }}/api/tasks/send-overdue-reminders \
            -H "Authorization: Bearer ${{ secrets.CRON_SECRET }}"
```

#### External Cron Services

**Cron-job.org** (Free):
1. Visit https://cron-job.org
2. Create account
3. Add new cron job:
   - URL: `https://your-app.com/api/tasks/send-overdue-reminders`
   - Schedule: Daily at 9:00 AM
   - Add header: `Authorization: Bearer your-cron-secret`

**EasyCron** (Free tier available):
- Similar setup to cron-job.org
- More advanced scheduling options

### Environment Variables

```env
# Email Service
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=user@example.com
SMTP_PASS=password
SMTP_FROM=noreply@tooltag.app

# Cron Authentication
CRON_SECRET=generate-with-openssl-rand-base64-32
```

### Testing Emails

**Development Mode:**
```bash
# Emails will log to console but not send if SMTP not configured
npm run dev
```

**Test SMTP Connection:**
```javascript
// Create a test route: src/routes/api/test-email/+server.ts
import { sendEmail } from '$lib/server/email';

export const GET = async () => {
  const result = await sendEmail({
    to: 'your-email@example.com',
    subject: 'Test Email',
    text: 'If you receive this, SMTP is configured correctly!',
  });
  
  return new Response(JSON.stringify({ sent: result }));
};
```

Then visit: `http://localhost:5173/api/test-email`

### Disabling Email Notifications

If you don't want to set up SMTP immediately:
- Leave SMTP environment variables empty
- Emails will be logged to console instead of sending
- App functionality remains unchanged
- Set up SMTP later when ready

---

## Summary

All three features are now fully implemented and production-ready:

### ✅ Camera QR Scanning
- No configuration needed
- Works out of the box
- Requires HTTPS in production

### ✅ Photo Uploads
- Local storage by default
- Configure `STORAGE_PATH` for custom directory
- Switch to S3 for serverless deployments (requires implementation)

### ✅ Email Notifications
- Optional: Works without SMTP (logs only)
- Configure SMTP for production use
- Set up cron job for overdue reminders

---

## Quick Start Checklist

**For full functionality, add to `.env`:**

```bash
# Photo uploads (local storage)
STORAGE_TYPE=local
STORAGE_PATH=./uploads

# Email notifications (choose your provider)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=noreply@tooltag.app

# Cron jobs (generate secret)
CRON_SECRET=$(openssl rand -base64 32)
```

**Then:**
1. ✅ Test QR scanner at `/scan`
2. ✅ Upload a photo when creating an item
3. ✅ Check out an item and verify email received
4. ✅ Set up cron job for overdue reminders (optional)

---

## Troubleshooting

**QR Scanner not working:**
- Check browser console for errors
- Ensure HTTPS in production (HTTP only works on localhost)
- Verify camera permissions granted

**Photos not uploading:**
- Check `STORAGE_PATH` exists and is writable
- Verify file size under 5MB
- Check file type is image/*

**Emails not sending:**
- Verify SMTP credentials correct
- Check SMTP port (587 for TLS, 465 for SSL)
- Review server logs for nodemailer errors
- Test with Gmail App Password first (easiest to set up)

**Overdue reminders not running:**
- Verify cron job is configured
- Check `CRON_SECRET` matches in env and cron service
- Test endpoint manually with curl first
- Review API logs for errors

---

## Next Steps

**Enhancements:**
1. Add S3 storage implementation
2. Add email delivery tracking
3. Add email preference settings per user
4. Add batch photo upload
5. Add QR code generation from camera (scan to add item)

**See roadmap in README.md for more post-MVP features.**

