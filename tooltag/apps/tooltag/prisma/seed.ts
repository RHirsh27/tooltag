import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
	console.log('🌱 Seeding database...');

	// Create demo user
	const hashedPassword = await bcrypt.hash('password123', 10);
	const user = await prisma.user.upsert({
		where: { email: 'demo@tooltag.app' },
		update: {},
		create: {
			email: 'demo@tooltag.app',
			name: 'Demo User',
			password: hashedPassword,
		},
	});

	// Create demo organization
	const org = await prisma.organization.upsert({
		where: { slug: 'demo-org' },
		update: {},
		create: {
			name: 'Demo Organization',
			slug: 'demo-org',
		},
	});

	// Create membership
	await prisma.membership.upsert({
		where: {
			userId_organizationId: {
				userId: user.id,
				organizationId: org.id,
			},
		},
		update: {},
		create: {
			userId: user.id,
			organizationId: org.id,
			role: 'OWNER',
		},
	});

	// Create demo locations
	const warehouse = await prisma.location.create({
		data: {
			organizationId: org.id,
			name: 'Main Warehouse',
			description: 'Primary storage facility',
		},
	});

	const workshop = await prisma.location.create({
		data: {
			organizationId: org.id,
			name: 'Workshop',
			description: 'On-site workshop',
		},
	});

	// Create demo categories
	const powerTools = await prisma.category.create({
		data: {
			organizationId: org.id,
			name: 'Power Tools',
			description: 'Electric and battery-powered tools',
		},
	});

	const handTools = await prisma.category.create({
		data: {
			organizationId: org.id,
			name: 'Hand Tools',
			description: 'Manual tools',
		},
	});

	// Create demo items
	const drill = await prisma.item.create({
		data: {
			organizationId: org.id,
			name: 'Cordless Drill',
			description: '18V lithium-ion drill/driver',
			sku: 'DRL-001',
			serialNumber: 'SN12345',
			status: 'AVAILABLE',
			locationId: warehouse.id,
			categoryId: powerTools.id,
		},
	});

	const hammer = await prisma.item.create({
		data: {
			organizationId: org.id,
			name: 'Claw Hammer',
			description: '16oz steel hammer',
			sku: 'HMR-001',
			status: 'AVAILABLE',
			locationId: workshop.id,
			categoryId: handTools.id,
		},
	});

	// Create tags for items
	const { nanoid } = await import('nanoid');
	await prisma.tag.create({
		data: {
			organizationId: org.id,
			itemId: drill.id,
			uid: nanoid(10),
		},
	});

	await prisma.tag.create({
		data: {
			organizationId: org.id,
			itemId: hammer.id,
			uid: nanoid(10),
		},
	});

	// Log seed summary
	const counts = {
		users: await prisma.user.count(),
		orgs: await prisma.organization.count(),
		items: await prisma.item.count(),
		tags: await prisma.tag.count(),
	};

	console.log('✅ Seeding complete:');
	console.log(`   Users: ${counts.users}`);
	console.log(`   Organizations: ${counts.orgs}`);
	console.log(`   Items: ${counts.items}`);
	console.log(`   Tags: ${counts.tags}`);
	console.log('\n📧 Demo login: demo@tooltag.app / password123');
}

main()
	.catch((e) => {
		console.error('❌ Seeding failed:', e);
		process.exit(1);
	})
	.finally(async () => {
		await prisma.$disconnect();
	});
