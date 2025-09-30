// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
import type { User, Membership, Organization } from '@prisma/client';

declare global {
	namespace App {
		interface Locals {
			user?: User;
			memberships?: (Membership & { organization: Organization })[];
		}
		// interface Error {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}

export {};
