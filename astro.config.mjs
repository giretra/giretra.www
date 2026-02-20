// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'Giretra',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/giretra' }],
			sidebar: [
				{
					label: 'Learn',
					items: [
						{ label: 'Rules', slug: 'learn' },
						{ label: 'Coming from Belote?', slug: 'coming-from-belote' },
						{ label: 'Vocabulary', slug: 'vocabulary' },
					],
				},
				{
					label: 'Build Your Bot',
					items: [
						{ label: 'Getting Started', slug: 'build-your-bot' },
					],
				},
				{
					label: 'Contribute',
					items: [
						{ label: 'How to Contribute', slug: 'contribute' },
					],
				},
			],
		}),
	],
});
