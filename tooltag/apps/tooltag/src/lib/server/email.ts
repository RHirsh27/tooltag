import nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';
import { env } from '@tooltag/config/env';

/**
 * Email service for sending notifications.
 * Uses SMTP configuration from environment variables.
 */

let transporter: Transporter | null = null;

/**
 * Initialize email transporter
 */
function getTransporter(): Transporter | null {
	if (transporter) {
		return transporter;
	}

	// Check if SMTP is configured
	if (!env.SMTP_HOST || !env.SMTP_PORT || !env.SMTP_USER || !env.SMTP_PASS) {
		console.warn('SMTP not configured - emails will not be sent');
		return null;
	}

	transporter = nodemailer.createTransport({
		host: env.SMTP_HOST,
		port: env.SMTP_PORT,
		secure: env.SMTP_PORT === 465, // true for 465, false for other ports
		auth: {
			user: env.SMTP_USER,
			pass: env.SMTP_PASS,
		},
	});

	return transporter;
}

interface EmailOptions {
	to: string;
	subject: string;
	text: string;
	html?: string;
}

/**
 * Send an email
 */
export async function sendEmail(options: EmailOptions): Promise<boolean> {
	const transport = getTransporter();

	if (!transport) {
		console.log('[Email] Skipping email send (SMTP not configured):', options.subject);
		return false;
	}

	try {
		await transport.sendMail({
			from: env.SMTP_FROM || '"ToolTag" <noreply@tooltag.app>',
			to: options.to,
			subject: options.subject,
			text: options.text,
			html: options.html || options.text.replace(/\n/g, '<br>'),
		});

		console.log(`[Email] Sent to ${options.to}: ${options.subject}`);
		return true;
	} catch (error) {
		console.error('[Email] Failed to send:', error);
		return false;
	}
}

/**
 * Send checkout notification email
 */
export async function sendCheckoutNotification(params: {
	userEmail: string;
	userName: string;
	itemName: string;
	dueDate?: Date;
	organizationName: string;
}): Promise<boolean> {
	const dueDateText = params.dueDate
		? `\n\nDue Date: ${params.dueDate.toLocaleDateString()}`
		: '';

	const text = `
Hello ${params.userName},

You have successfully checked out the following item:

Item: ${params.itemName}
Organization: ${params.organizationName}${dueDateText}

Please remember to check it back in when you're done.

---
ToolTag - Equipment Tracking
${env.PUBLIC_APP_URL}
	`.trim();

	const html = `
<!DOCTYPE html>
<html>
<head>
	<style>
		body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
		.container { max-width: 600px; margin: 0 auto; padding: 20px; }
		.header { background: #2563eb; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
		.content { background: #f8f9fa; padding: 20px; border-radius: 0 0 8px 8px; }
		.item-card { background: white; padding: 15px; border-radius: 6px; margin: 15px 0; border-left: 4px solid #2563eb; }
		.footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
		.btn { display: inline-block; padding: 12px 24px; background: #2563eb; color: white; text-decoration: none; border-radius: 6px; margin: 10px 0; }
	</style>
</head>
<body>
	<div class="container">
		<div class="header">
			<h1>Item Checked Out</h1>
		</div>
		<div class="content">
			<p>Hello ${params.userName},</p>
			<p>You have successfully checked out the following item:</p>
			<div class="item-card">
				<strong>Item:</strong> ${params.itemName}<br>
				<strong>Organization:</strong> ${params.organizationName}
				${params.dueDate ? `<br><strong>Due Date:</strong> ${params.dueDate.toLocaleDateString()}` : ''}
			</div>
			<p>Please remember to check it back in when you're done.</p>
			<a href="${env.PUBLIC_APP_URL}/dashboard" class="btn">View Dashboard</a>
		</div>
		<div class="footer">
			<p>ToolTag - Equipment Tracking</p>
			<p><a href="${env.PUBLIC_APP_URL}">${env.PUBLIC_APP_URL}</a></p>
		</div>
	</div>
</body>
</html>
	`.trim();

	return sendEmail({
		to: params.userEmail,
		subject: `Checked Out: ${params.itemName}`,
		text,
		html,
	});
}

/**
 * Send checkin notification email
 */
export async function sendCheckinNotification(params: {
	userEmail: string;
	userName: string;
	itemName: string;
	organizationName: string;
	checkedOutAt: Date;
}): Promise<boolean> {
	const duration = Math.ceil(
		(Date.now() - params.checkedOutAt.getTime()) / (1000 * 60 * 60 * 24)
	);

	const text = `
Hello ${params.userName},

The following item has been checked back in:

Item: ${params.itemName}
Organization: ${params.organizationName}
Duration: ${duration} day(s)

Thank you for returning it on time!

---
ToolTag - Equipment Tracking
${env.PUBLIC_APP_URL}
	`.trim();

	const html = `
<!DOCTYPE html>
<html>
<head>
	<style>
		body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
		.container { max-width: 600px; margin: 0 auto; padding: 20px; }
		.header { background: #10b981; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
		.content { background: #f8f9fa; padding: 20px; border-radius: 0 0 8px 8px; }
		.item-card { background: white; padding: 15px; border-radius: 6px; margin: 15px 0; border-left: 4px solid #10b981; }
		.footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
	</style>
</head>
<body>
	<div class="container">
		<div class="header">
			<h1>Item Returned</h1>
		</div>
		<div class="content">
			<p>Hello ${params.userName},</p>
			<p>The following item has been checked back in:</p>
			<div class="item-card">
				<strong>Item:</strong> ${params.itemName}<br>
				<strong>Organization:</strong> ${params.organizationName}<br>
				<strong>Duration:</strong> ${duration} day(s)
			</div>
			<p>Thank you for returning it on time!</p>
		</div>
		<div class="footer">
			<p>ToolTag - Equipment Tracking</p>
			<p><a href="${env.PUBLIC_APP_URL}">${env.PUBLIC_APP_URL}</a></p>
		</div>
	</div>
</body>
</html>
	`.trim();

	return sendEmail({
		to: params.userEmail,
		subject: `Returned: ${params.itemName}`,
		text,
		html,
	});
}

/**
 * Send overdue item reminder email
 */
export async function sendOverdueReminder(params: {
	userEmail: string;
	userName: string;
	itemName: string;
	dueDate: Date;
	organizationName: string;
	daysOverdue: number;
}): Promise<boolean> {
	const text = `
Hello ${params.userName},

REMINDER: The following item is overdue:

Item: ${params.itemName}
Organization: ${params.organizationName}
Due Date: ${params.dueDate.toLocaleDateString()}
Days Overdue: ${params.daysOverdue}

Please check it in as soon as possible.

---
ToolTag - Equipment Tracking
${env.PUBLIC_APP_URL}
	`.trim();

	const html = `
<!DOCTYPE html>
<html>
<head>
	<style>
		body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
		.container { max-width: 600px; margin: 0 auto; padding: 20px; }
		.header { background: #ef4444; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
		.content { background: #f8f9fa; padding: 20px; border-radius: 0 0 8px 8px; }
		.item-card { background: white; padding: 15px; border-radius: 6px; margin: 15px 0; border-left: 4px solid #ef4444; }
		.footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
		.btn { display: inline-block; padding: 12px 24px; background: #ef4444; color: white; text-decoration: none; border-radius: 6px; margin: 10px 0; }
		.warning { background: #fef2f2; padding: 10px; border-radius: 6px; color: #991b1b; margin: 10px 0; }
	</style>
</head>
<body>
	<div class="container">
		<div class="header">
			<h1>⚠️ Item Overdue</h1>
		</div>
		<div class="content">
			<p>Hello ${params.userName},</p>
			<div class="warning">
				<strong>REMINDER:</strong> The following item is now overdue.
			</div>
			<div class="item-card">
				<strong>Item:</strong> ${params.itemName}<br>
				<strong>Organization:</strong> ${params.organizationName}<br>
				<strong>Due Date:</strong> ${params.dueDate.toLocaleDateString()}<br>
				<strong>Days Overdue:</strong> ${params.daysOverdue}
			</div>
			<p>Please check it in as soon as possible.</p>
			<a href="${env.PUBLIC_APP_URL}/dashboard/assignments" class="btn">View My Assignments</a>
		</div>
		<div class="footer">
			<p>ToolTag - Equipment Tracking</p>
			<p><a href="${env.PUBLIC_APP_URL}">${env.PUBLIC_APP_URL}</a></p>
		</div>
	</div>
</body>
</html>
	`.trim();

	return sendEmail({
		to: params.userEmail,
		subject: `⚠️ Overdue: ${params.itemName}`,
		text,
		html,
	});
}

/**
 * Send team member invite email
 */
export async function sendTeamInvite(params: {
	toEmail: string;
	toName: string;
	organizationName: string;
	inviterName: string;
	role: string;
}): Promise<boolean> {
	const text = `
Hello ${params.toName},

${params.inviterName} has invited you to join ${params.organizationName} on ToolTag.

Role: ${params.role}

Click the link below to accept the invitation and create your account:

${env.PUBLIC_APP_URL}/signup?org=${encodeURIComponent(params.organizationName)}

---
ToolTag - Equipment Tracking
${env.PUBLIC_APP_URL}
	`.trim();

	const html = `
<!DOCTYPE html>
<html>
<head>
	<style>
		body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
		.container { max-width: 600px; margin: 0 auto; padding: 20px; }
		.header { background: #2563eb; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
		.content { background: #f8f9fa; padding: 20px; border-radius: 0 0 8px 8px; }
		.invite-card { background: white; padding: 20px; border-radius: 6px; margin: 15px 0; text-align: center; }
		.footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
		.btn { display: inline-block; padding: 12px 24px; background: #2563eb; color: white; text-decoration: none; border-radius: 6px; margin: 10px 0; }
	</style>
</head>
<body>
	<div class="container">
		<div class="header">
			<h1>Team Invitation</h1>
		</div>
		<div class="content">
			<p>Hello ${params.toName},</p>
			<p>${params.inviterName} has invited you to join <strong>${params.organizationName}</strong> on ToolTag.</p>
			<div class="invite-card">
				<p><strong>Role:</strong> ${params.role}</p>
				<a href="${env.PUBLIC_APP_URL}/signup?org=${encodeURIComponent(params.organizationName)}" class="btn">Accept Invitation</a>
			</div>
			<p>ToolTag helps teams track equipment with QR codes, manage check-outs, and maintain accountability.</p>
		</div>
		<div class="footer">
			<p>ToolTag - Equipment Tracking</p>
			<p><a href="${env.PUBLIC_APP_URL}">${env.PUBLIC_APP_URL}</a></p>
		</div>
	</div>
</body>
</html>
	`.trim();

	return sendEmail({
		to: params.toEmail,
		subject: `You're invited to join ${params.organizationName} on ToolTag`,
		text,
		html,
	});
}

