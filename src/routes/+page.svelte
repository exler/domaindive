<svelte:head>
    <title>DomainDive - Analyze any domain</title>
</svelte:head>

<main class="max-w-xl mx-auto px-6 py-32">
    <div class="text-center mb-12">
        <img src="/images/logo.png" alt="DomainDive Logo" class="w-48 h-48 mx-auto mb-6" />
        <h1 class="text-4xl font-light text-slate-800 tracking-tight mb-3">DomainDive</h1>
        <p class="text-slate-600 text-sm">Analyze WHOIS, DNS, SSL, and server location</p>
    </div>

    <form method="get" action="/analysis">
        <div class="flex gap-3">
            <input
                type="text"
                name="domain"
                placeholder="example.com"
                class="flex-1 px-4 py-3 bg-white/80 backdrop-blur border border-sky-200 rounded-lg text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-sky-400 focus:border-transparent shadow-sm"
                required
            />
            <button
                type="submit"
                class="px-6 py-3 bg-sky-600 text-white font-medium rounded-lg hover:bg-sky-700 focus:outline-none focus:ring-2 focus:ring-sky-400 focus:ring-offset-2 transition-colors shadow-sm"
            >
                Dive In
            </button>
        </div>
    </form>

    <div class="mt-16 grid grid-cols-2 gap-4 text-center">
        <div class="p-4 bg-white/50 backdrop-blur rounded-lg">
            <svg class="w-6 h-6 text-sky-600 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
            </svg>
            <span class="text-sm text-slate-700">WHOIS</span>
        </div>
        <div class="p-4 bg-white/50 backdrop-blur rounded-lg">
            <svg class="w-6 h-6 text-sky-600 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"
                />
            </svg>
            <span class="text-sm text-slate-700">DNS Records</span>
        </div>
        <div class="p-4 bg-white/50 backdrop-blur rounded-lg">
            <svg class="w-6 h-6 text-sky-600 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
            </svg>
            <span class="text-sm text-slate-700">SSL Certificate</span>
        </div>
        <div class="p-4 bg-white/50 backdrop-blur rounded-lg">
            <svg class="w-6 h-6 text-sky-600 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                />
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                />
            </svg>
            <span class="text-sm text-slate-700">Geolocation</span>
        </div>
    </div>
</main>
