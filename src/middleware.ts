import createIntlMiddleware from 'next-intl/middleware'
import { NextResponse, type NextRequest } from 'next/server'
import { routing } from '@/i18n/routing'
import { updateSession } from '@/lib/supabase/middleware'

const intlMiddleware = createIntlMiddleware(routing)

// Routes that never require auth. Compared against the path with the locale
// prefix stripped (e.g. "/login", "/bills/123/share").
const PUBLIC_PATTERNS = [
  /^\/login$/,
  /^\/line-web-return$/,
  /^\/bills\/[^/]+\/share$/,
]

function stripLocale(pathname: string) {
  const seg = pathname.split('/')[1]
  if (routing.locales.includes(seg as never)) {
    return '/' + pathname.split('/').slice(2).join('/')
  }
  return pathname
}

export async function middleware(request: NextRequest) {
  const { response, user, supabase } = await updateSession(request)

  const pathname = request.nextUrl.pathname
  const bare = stripLocale(pathname) || '/'
  const isPublic = PUBLIC_PATTERNS.some((re) => re.test(bare))
  const isOnboarding = bare === '/onboarding'

  const locale =
    routing.locales.find((l) => pathname.startsWith(`/${l}`)) ?? routing.defaultLocale

  // Not signed in → allow only public routes
  if (!user && !isPublic) {
    return NextResponse.redirect(new URL(`/${locale}/login`, request.url))
  }

  // Signed in but hitting login → send home
  if (user && bare === '/login') {
    return NextResponse.redirect(new URL(`/${locale}/home`, request.url))
  }

  // Signed in → enforce onboarding completion
  if (user && !isPublic) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('onboarding_completed')
      .eq('id', user.id)
      .maybeSingle()

    if (!profile?.onboarding_completed && !isOnboarding) {
      return NextResponse.redirect(new URL(`/${locale}/onboarding`, request.url))
    }
    if (profile?.onboarding_completed && isOnboarding) {
      return NextResponse.redirect(new URL(`/${locale}/home`, request.url))
    }
  }

  // Run i18n routing (which may rewrite/redirect), copying over refreshed cookies.
  const intlResponse = intlMiddleware(request)
  response.cookies.getAll().forEach((c) => intlResponse.cookies.set(c))
  return intlResponse
}

export const config = {
  matcher: ['/', '/((?!api|_next|_vercel|.*\\..*).*)'],
}
