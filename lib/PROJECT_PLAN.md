# Project Plan — Intelligent Job Search Assistant

## Repository Structure
This project is split across two repositories:

- **Backend**: [https://github.com/Farukfba/skill-seeker-service] — TanStack Start (Cloudflare Workers) server routes, Claude API (claude-haiku-4-5-20251001), MCP tool-use for Adzuna job search, Supabase integration
- **Mobile**: [https://github.com/Farukfba/job-search-assistant] — Flutter app (iOS & Android)

Each repo has its own deploy pipeline: the backend deploys via Lovable to Cloudflare Workers, the mobile app is built/run via Flutter.

## Phases & Target Dates
- Phase 1: Setup & accounts — [date] ✅
- Phase 2: Backend server — [date] ✅
- Phase 3: Supabase database — [date]
- Phase 4: Flutter app — [date]
- Phase 5: Test, document & publish — [date]

## Screens
1. Onboarding / Auth
2. CV Upload
3. Job Search
4. Job Detail + Match Score
5. Cover Letter / Interview Prep
6. Application Tracker (Kanban)

## State Management
Riverpod — providers for: user/profile, search results, selected job, application tracker list.

## Backend Endpoints (live)
- POST /api/public/parse-cv
- POST /api/public/search-jobs
- POST /api/public/match-job
- POST /api/public/cover-letter
- POST /api/public/interview-prep

All AI endpoints use claude-haiku-4-5-20251001 via @anthropic-ai/sdk.

## Notes / Risks
- Two-repo split chosen because Lovable's GitHub integration only creates new repos, not push-to-existing.
- Adzuna search currently hardcoded to "gb" country code — revisit if testing non-UK locations.
- Cover letter / interview prep quality with Haiku to be monitored — may upgrade those two endpoints to Sonnet if needed.
