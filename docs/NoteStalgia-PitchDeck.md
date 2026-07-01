# NoteStalgia™ by Oscillomind — Pitch Decks

> *"Sound that takes you back."*
> A music‑reminiscence and sensory‑calm platform for care homes, delivered on iPad.

This document contains:
1. **Product & flow summary** (what the app does today + where production is headed)
2. **Deck A — NHS Grant Scheme** (innovation / evidence‑generation framing)
3. **Deck B — Care UK Board** (operational / commercial framing)

Each deck is written slide‑by‑slide so it can be pasted directly into PowerPoint, Keynote, or Google Slides.

> **Living docs:** product/engineering detail is maintained in [`IMPLEMENTATION_PLAN.md`](./IMPLEMENTATION_PLAN.md). Update both when tenancy, auth, or architecture decisions change.

---

## 1. Product & flow summary

**What it is:** A person‑centred, non‑pharmacological calm and reminiscence tool for one‑to‑one and group sessions in residential and dementia care. It pairs a **staff (supervisor) workflow** with a deliberately **low‑text, touch‑first resident surface**, so residents interact directly with music and immersive nature visuals while staff capture lightweight wellbeing signals.

**Two surfaces, one device:**
- **Supervisor surface** (text‑rich): org‑scoped sign‑in, home picker, curated resident roster, person‑centred profiles, session prep, feedback capture, history.
- **Resident surface** (low‑text, accessible): floating instrument glyphs, music‑reactive orb, immersive "calm room" nature visuals — no reading required.

**Tenancy & access (POC today, production target):**
- **Organisation → care home → wing → resident.** Staff belong to a care‑home company (tenant); residents and sessions are scoped to homes within that company.
- **Sign‑in:** work **email + PIN** (domain‑validated per organisation). No biometrics — GDPR‑aligned, PIN‑only auth.
- **Roles:** floor **Supervisor**, **Home Admin** (one or more homes), **Company Admin** (whole estate — web dashboard audience).
- **Multi‑home staff:** supervisors assigned to several homes pick **which home they're working at today**, then see only that home's roster.
- **Curated roster at scale:** pinned residents, recent sessions, due for a visit, wing filter, **search by name / room / wing**, cards or compact rows, browse‑all — designed to stay fast from 30 to 3,000+ residents per company (server‑side search in production).

**Core flows:**

| Flow | What happens | Why it matters |
|---|---|---|
| **Supervisor sign‑in → Home (if multi‑site) → Welcome → Roster** | Staff log in with work email + PIN; optional home picker; animated welcome; **home‑scoped curated roster** | Secure, tenant‑aware entry into the working day — right residents, right building |
| **Person‑centred profiles** | Likes/dislikes, preferred lighting, scent, touch comfort, reminiscence themes, sound‑shaping preferences, age, favourite genre, curated playlists | Care that adapts to the individual, not the average |
| **New‑resident music discovery (calibration)** | Age input → 6 timed retro snippets ordered to the resident's *peak listening years (≈15–30)* → resident taps a simple traffic‑light smiley (pleasant / neutral / unpleasant) per clip → builds a tuned playlist | Personalises the library in minutes, even for residents who can't self‑report |
| **One‑to‑one calm session** | Gentle staff→resident handoff → resident taps instrument glyphs to play → music‑reactive orb + equalizer → optional immersive nature "calm room" → settling pause | Residents lead; staff support. Low agitation, high agency |
| **Session feedback** | Sequential 1–10 ratings (mood, alertness, emotional state, lucidity) + free note + automatic telemetry (genres played, track changes, immersive entries, duration) | Lightweight, repeatable wellbeing signal over time |
| **Group session** | Compiles a cross‑resident playlist from top‑scoring tracks across the **current home's** roster → shared playback → group feedback (morale, alertness, lucidity, engagement) | Social, communal reminiscence with measurable outcomes |
| **Insights & exports (production)** | Event‑first telemetry → aggregation marts → in‑app supervisor view + **web admin dashboard** (Company Admin) + DPIA‑gated researcher cohort exports | Operational evidence for CQC/families; independent evaluation without manual charting |

**Explicitly out of scope for v1 production:** biometric / Face ID linking, IoT smart‑room orchestration (lighting, VR, TV mirroring). Sessions start via **supervisor handoff** only.

**Design principles baked in:** accessibility‑first (VoiceOver labels, Reduce‑Motion support), a deliberately non‑clinical tone ("a small pause — not a report card"), era‑personalised music, sensory calm throughout, **offline‑first** on the care floor (poor Wi‑Fi).

**Production architecture (from implementation plan):**
- **Cloud:** AWS, primary region **eu‑west‑2 (London)** for UK data residency; EU regions for expansion.
- **Data:** **MongoDB Atlas** (sharded, zone‑pinned per tenant), Redis cache, S3 + CloudFront for media/portraits.
- **Compute:** **Kubernetes (EKS)**, GitOps‑managed; **.NET modular monolith** backend with DDD bounded contexts.
- **Clients:** modular **iOS** app (SPM) + **web admin dashboard** for company‑level reporting and staff onboarding.
- **ML:** phased recommender (heuristic → classical ML → deep learning) behind one stable API.
- **Scale target:** entire UK market — **~17,000 care homes** — without re‑architecture; tenant = care‑home company.

**Production note (funding relevance):** The current proof‑of‑concept streams open/CC placeholder audio and stores state on‑device with **mock tenancy**. A funded pilot requires: **licensed music streaming API**, the **hosted backend + Atlas + EKS stack** above, **server‑side roster search & governance**, researcher‑grade **event/aggregation pipeline**, and **GDPR Art. 9** controls (consent, DSAR, crypto‑shredding, audit) — core cost lines in any grant application.

---

## 2. Deck A — NHS Grant Scheme

*Framing: innovation adoption, non‑pharmacological intervention, evidence generation, and scalability across the care/health interface.*

### Slide 1 — Title
**NoteStalgia™ by Oscillomind**
Sound that takes you back.
*A non‑pharmacological calm & reminiscence platform for dementia and elderly care.*
[Applicant / contact / date]

### Slide 2 — The problem
- Agitation, anxiety and distress are among the most common and hardest‑to‑manage symptoms in dementia care.
- Antipsychotics remain over‑relied upon despite known harms; reducing inappropriate prescribing is a long‑standing NHS priority.
- Non‑pharmacological interventions (music, reminiscence, sensory) are evidence‑backed but inconsistently delivered — they depend on staff time, skill, and the right materials in the moment.

### Slide 3 — Why music & reminiscence
- Music reaches people when language and memory fade; autobiographical "peak years" music is especially powerful.
- Established benefits: reduced agitation, improved mood, increased engagement and lucid moments, better staff–resident connection.
- The gap is **delivery at scale and consistency** — and **capturing outcomes** to prove impact.

### Slide 4 — Our solution
A single iPad app that lets residents *lead* a calm music experience while staff capture wellbeing signals with almost no overhead — **built for multi‑home care companies from day one.**
- **Resident surface:** touch‑first instrument glyphs, music‑reactive visuals, immersive nature "calm room" — no reading required.
- **Staff surface:** org‑scoped email + PIN sign‑in, home picker, **curated roster** (search, wings, pins, due/recent), person‑centred profiles, rapid calibration, one‑to‑one and group sessions, structured feedback.
- **Company surface (production):** web dashboard for estate‑wide trends, exports, and staff onboarding — tenant‑isolated, audit‑logged.

### Slide 5 — How it personalises (the differentiator)
- **Era‑matched discovery:** clips are ordered to each resident's peak listening years; residents respond with a simple traffic‑light smiley.
- Builds a tuned, individual playlist in minutes — works even for residents who can't self‑report.
- Person‑centred profile captures sensory preferences (light, scent, touch, onset gentleness) so each session fits the individual.
- **Roster intelligence:** staff see who needs a visit, who they work with often, and can find any resident by name or room in seconds — even across large homes.

### Slide 6 — Built‑in outcome measurement
Every session captures, with minimal staff effort:
- Sequential 1–10 ratings: **mood, alertness, emotional state, lucidity** (group adds **morale & engagement**).
- Objective telemetry: genres played, track changes, immersive entries, session duration.
- Longitudinal history per resident → a wellbeing trend, not a one‑off note.
- **Production:** event‑first pipeline → pseudonymized cohort exports for researchers (DPIA‑gated, k‑anonymity, full audit).
*This makes NoteStalgia™ a ready‑made data instrument for an evaluation study.*

### Slide 7 — Evidence‑generation plan (what the grant funds)
- **Phase 1 — Pilot (3–6 months):** deploy across N homes; usability, adoption, staff‑time impact.
- **Phase 2 — Evaluation:** measure agitation incidents, PRN/antipsychotic use, wellbeing scores vs. baseline.
- **Phase 3 — Evidence pack:** outcomes write‑up to support wider NHS/social‑care adoption and NICE‑aligned framing.

Grant funding would cover six essential cost lines alongside pilot deployment:

| Cost line | Why it is required |
|---|---|
| **Embedded researcher** | Independent evaluation design, ethics/IRB, data collection & analysis, and a publishable outcomes report. Budgeted at **0.5 FTE × 18 months (£45,000)** — enough for credible independent evaluation while the app auto‑captures most outcome data. |
| **Product development (Oscillomind)** | The prototype shell, UX, tenancy/roster POC, and outcome instrument exist; a funded pilot still needs substantial engineering: licensed streaming API, **AWS/EKS backend + MongoDB Atlas**, server‑side roster/search, **insights aggregation pipeline**, offline‑first iOS sync, web admin dashboard, pilot‑site support, GDPR Art. 9 hardening, and bug fixes under real care‑floor conditions. Budgeted as founder/lead developer time (~0.7 FTE over 18 months, **£70,000**). |
| **Licensed music streaming API** | The current prototype uses open/CC placeholder streams for demonstration. A production pilot requires a **third‑party music streaming API with fully cleared, commercial‑use licences** (e.g. era‑matched catalogues, genre browsing, on‑demand playback). This is a recurring subscription cost for the pilot period and is non‑negotiable for safe, scalable deployment in care settings. |
| **Cloud services** | Production pilot requires **AWS (eu‑west‑2)**: EKS, **MongoDB Atlas** (UK‑pinned), Redis, S3/CloudFront, monitoring, backups, WAF — **plus AI development tooling** (estimated **Anthropic Claude** subscription for the lead developer during the build). The POC runs in‑memory on device; a multi‑site study needs reliable, GDPR‑aligned cloud ops for the pilot period. |
| **Tech hardware (development & test devices)** | **£10,000** dedicated hardware budget for Oscillomind engineering: Mac development machines, test iPads covering multiple iOS versions/screen sizes, peripherals, and spare units for on‑site debugging — so integration, streaming, and pilot hotfixes are validated on real devices throughout the 18‑month build. |
| **Pilot operations** | Site onboarding, staff training, travel to pilot homes, and a part‑time pilot coordinator during active data collection. Pilot sites use existing care‑home iPads where available; development hardware is separate from resident‑facing kit. |

Without the researcher, licensed music infrastructure, cloud hosting, development hardware, and ongoing engineering, the project cannot move from **working prototype** to **evidence‑backed, legally compliant care intervention**.

### Slide 8 — Alignment with NHS priorities
- Reducing inappropriate antipsychotic prescribing in dementia.
- Personalised, person‑centred care.
- Prevention and quality of life over medicalisation.
- Digital innovation that is low‑cost, low‑training, and deployable on existing hardware.

### Slide 9 — Why now / why us
- Working, accessibility‑first prototype already built (iPad, iOS 17+) — including **org/home tenancy, email + PIN auth, and curated roster** in the POC.
- Architecture and delivery plan documented for **UK‑wide scale (~17,000 homes)** with GDPR Art. 9 controls designed in, not bolted on.
- Designed *with* care‑setting constraints in mind (low text, Reduce‑Motion, VoiceOver, gentle non‑clinical tone, **offline‑first**).
- Ready for a structured pilot — the grant accelerates evidence, licensing, cloud production, and evaluation — not basic app build.

### Slide 10 — The ask & use of funds

**Recommended ask: £190,000 over 18 months** (5–8 care homes)  
**Minimum viable pilot: £132,000 over 12 months** (3–5 care homes)

| Budget line | Recommended (18 mo) | Min. viable (12 mo) | % | Detail |
|---|---|---|---|---|
| **Researcher (evaluation lead)** | **£45,000** | **£32,000** | ~24% | 0.5 FTE × 18 months (recommended) or 0.4 FTE × 12 months (lean). Protocol, ethics/IRB, site liaison, analysis, and publishable report. App auto‑capture reduces manual data collection — evaluation effort focused on interpretation and outcomes write‑up. Assumes ~£40k/year pro‑rata salary + ~20% on‑costs. |
| **Product development — Oscillomind (lead developer)** | **£70,000** | £50,000 | ~37% | ~0.7 FTE × 18 months (recommended) or ~0.5 FTE × 12 months (lean). Covers: licensed streaming API integration; **.NET backend + iOS modularisation + web dashboard**; **MongoDB Atlas roster search & tenant isolation**; **event/aggregation pipeline** for researcher export; offline sync; pilot‑site support & hotfixes; GDPR/security hardening. Equivalent to ~140 developer days at £500/day. |
| **Licensed music streaming API** | £16,000 | £12,000 | ~8% | B2B streaming subscription for commercial/care‑setting use across pilot homes (~£650–900/month × pilot duration), plus setup/onboarding fee and usage overage buffer. Provider TBD (e.g. 7digital, Tuned Global, or equivalent B2B catalogue API with cleared public‑performance/commercial terms). |
| **Cloud services** | **£11,000** | **£6,500** | ~6% | **~£9,100** AWS EKS + **MongoDB Atlas** (UK region), Redis, S3/CloudFront, monitoring, backups (~£500/mo × 18 mo). **~£900** estimated **Anthropic Claude** subscription for lead developer (Pro ~£20/mo × 18 mo, plus allowance for Max‑tier months during streaming/API integration). Lean: ~£5,520 hosting + ~£480 Claude Pro (12 mo). |
| **Tech hardware (development & test devices)** | **£10,000** | £6,000 | ~5% | Developer Mac(s), test iPads (multiple generations/screen sizes), cables, and spare units for field debugging. Required for streaming API integration, device‑specific QA, TestFlight builds, and on‑site pilot support — not resident‑facing deployment kit (pilot homes use existing iPads). |
| **Pilot deployment & operations** | £26,000 | £18,000 | ~14% | 5–8 home rollout: travel & site visits (~£5k), staff training & onboarding materials (~£4k), part‑time pilot coordinator during active collection (~£10–12k), MDM/app provisioning on homes' existing devices (~£3k). |
| **Contingency & dissemination** | £12,000 | £7,500 | ~6% | Open‑access publication, conference presentation, ethics amendments, streaming tier upgrade if usage exceeds forecast, 1–2 extra pilot sites. |
| **Total** | **£190,000** | **£132,000** | 100% | |

**What development time delivers (recommended budget):**
- Months 1–3: streaming API selection, licensing sign‑off, integration, replace POC placeholder audio; **AWS/EKS + Atlas** staging/production; identity (email + PIN, tenant RBAC).
- Months 2–5: era‑matched search/discovery pipeline wired to licensed catalogue; **server‑side roster search**; offline/cache + local outbox sync; **event capture** for sessions/wellbeing.
- Months 4–12: **aggregation marts + web dashboard**; researcher export; staff onboarding/invites; pilot support (fortnightly releases).
- Months 4–18: pilot support, incident response, accessibility fixes from the floor.
- Ongoing: security review, DPIA support, app store / MDM for care‑home iPads; observability, backups, and cost control.

**Deliverables:**
- Multi‑site pilot across 5–8 care homes with **licensed music live in app**.
- **Hosted, tenant‑isolated backend** (UK data residency) replacing on‑device mock state.
- Independent evaluation led by embedded researcher.
- Outcome dataset (wellbeing scores, incident/PRN trends, session telemetry) via **governed aggregation pipeline**.
- Peer‑shareable evidence pack suitable for NHS/social‑care adoption conversations.

**Outcome:** an evidence‑based, **legally compliant**, scalable non‑pharmacological tool ready for wider NHS and care‑sector adoption.

> **Stretch target (£223,000):** 10 homes, researcher at 0.7–1.0 FTE, enterprise streaming tier, extended development & post‑pilot hardening, higher cloud tier, expanded dev/test device pool — suitable for a larger NIHR/iCB innovation grant or multi‑region study.

### Slide 11 — Vision
From "calm in the moment" to a measurable, scalable standard of person‑centred reminiscence care across the UK's **~17,000 care homes** — and beyond.

---

## 3. Deck B — Care UK Board

*Framing: operational impact, quality ratings, staff experience, risk reduction, and commercial rollout.*

### Slide 1 — Title
**NoteStalgia™ by Oscillomind**
Sound that takes you back.
*Person‑centred calm & reminiscence — ready to pilot across Care UK homes.*
[Presenter / date]

### Slide 2 — The operational challenge
- Resident agitation and distress drive incidents, staff strain, and family concern.
- Non‑pharmacological calm techniques work — but are inconsistent and time‑hungry to deliver well.
- Quality regulators and families increasingly expect demonstrable, person‑centred wellbeing — not just compliance.
- Large estates need tools that work **per home, per wing, and company‑wide** — without leaking data between operators.

### Slide 3 — What NoteStalgia™ delivers
- A single iPad turns any room into a personalised calm space.
- Residents lead the experience; staff facilitate in minutes, not hours.
- Every session quietly produces a wellbeing record — evidence for CQC, families, and care planning.
- **Built for your estate structure:** company tenancy, home‑scoped rosters, role‑based access, company admin dashboard.

### Slide 4 — Resident experience (demo)
- Touch‑first instrument glyphs — tap an icon, music plays instantly.
- Music‑reactive orb and immersive nature "calm room."
- No reading, no menus, no clinical feel — designed for dementia and low‑mobility residents.
- Sessions start via **supervisor handoff** — simple, consent‑aware, no biometrics.

### Slide 5 — Staff experience (demo)
- **Work email + PIN** sign‑in → pick your home (if you cover several) → **curated roster** (pinned, recent, due, wing filter, search).
- Person‑centred profiles with curated playlists and discovery calibration in minutes.
- Post‑session feedback is four taps and an optional note — built around busy floors.
- **Offline‑first:** sessions continue when Wi‑Fi drops; telemetry syncs when back online.

### Slide 6 — Operational benefits
- **Reduced agitation** → fewer incidents, calmer floors, lower antipsychotic reliance.
- **Staff time saved** → personalisation, roster navigation, and outcome capture are near‑automatic.
- **Better family confidence** → visible, individualised engagement and progress.
- **Differentiated offer** → a modern, premium wellbeing experience across the estate.

### Slide 7 — Quality & compliance
- Built‑in, longitudinal wellbeing data (mood, alertness, emotional state, lucidity, engagement).
- Supports person‑centred care plans and CQC evidence of responsive, effective, caring service.
- **GDPR Art. 9 by design:** consent, audit logging, DSAR/erasure, UK data residency (AWS eu‑west‑2).
- Accessibility‑first (VoiceOver, Reduce‑Motion, low‑text).

### Slide 8 — Group sessions = activities, scaled
- Auto‑compiles a shared playlist from residents' best‑loved tracks **within the current home**.
- Turns reminiscence into a repeatable group activity with measured morale/engagement.
- Maximises impact per staff hour.

### Slide 9 — Fits your estate
- Runs on standard iPads — minimal hardware investment.
- **Multi‑home, multi‑wing** from one company tenant; staff see only what they're assigned to.
- **Web admin dashboard** (Company Admin): estate trends, exports, staff invites — scoped to Care UK data only.
- Light‑touch training; designed for real care‑floor conditions.

### Slide 10 — Rollout plan
- **Pilot:** 3–5 homes, 8–12 weeks; success metrics agreed up front (incidents, PRN use, staff feedback, family NPS).
- **Scale:** phased estate rollout with a simple per‑home licence; architecture sized for **full UK market** without re‑build.
- **Support:** onboarding, content updates, outcome dashboards, staff onboarding workflow.

### Slide 11 — Commercials
- Per‑home / per‑bed annual subscription [model TBD].
- Low capex (existing devices), predictable opex.
- ROI levers: incident reduction, agency/medication savings, occupancy via differentiation, quality‑rating uplift.

### Slide 12 — The ask
- Approve a **paid pilot** across [N] homes with agreed success metrics.
- Nominate a clinical/quality sponsor and pilot sites.
- Target decision: estate‑wide rollout on a successful pilot.

### Slide 13 — Vision
A calmer, more connected daily life for every resident — and a measurable, brand‑defining standard of person‑centred care for Care UK.

---

### Appendix — proof points to gather during pilot
- Agitation / incident frequency (pre vs. during).
- PRN and antipsychotic administration trends.
- Wellbeing scores over time (per resident, per home).
- Staff time per session and staff satisfaction.
- Family feedback / NPS.
- Session frequency, genre engagement, immersive uptake.
- Roster adoption (search, pins, due‑list usage) as a proxy for workflow fit.

### Appendix — budget assumptions (UK, 2026)

| Assumption | Value used |
|---|---|
| Researcher salary (pro‑rata, excl. on‑costs) | ~£38–42k/year FTE |
| Researcher budget (recommended / lean) | **£45,000** (0.5 FTE × 18 mo) / **£32,000** (0.4 FTE × 12 mo) |
| Employer on‑costs (NI, pension) | ~20% |
| Lead developer day rate equivalent | £500/day |
| Developer budget (recommended ask) | **£70,000** (~0.7 FTE × 18 months) |
| Developer FTE equivalent (recommended) | ~140 days over 18 months |
| Music API (B2B commercial tier) | ~£650–900/month + setup |
| Cloud services (AWS EKS + MongoDB Atlas, UK region) | ~£500/month × pilot duration |
| Anthropic Claude subscription (lead developer) | **~£900** recommended (18 mo) / **~£480** lean (12 mo Pro) |
| Tech hardware (dev Mac, test iPads, peripherals) | **£10,000** recommended / £6,000 lean |
| Pilot homes (recommended / lean) | 5–8 / 3–5 |
| Pilot duration (recommended / lean) | 18 / 12 months |
| Production scale target | ~17,000 UK care homes (tenant = care‑home company) |

**Why development is ~37% of the ask:** The app shell, UX, **tenancy/roster POC**, and outcome‑capture instrument already exist. Grant funding is not for greenfield build — it is for the **production gap**: legal music, **AWS/EKS + Atlas backend**, server‑side roster/search, **insights aggregation**, web dashboard, offline sync, researcher‑grade export, and keeping the app stable while real residents and staff use it daily. The **£70,000 development line** reflects the sustained engineering commitment required across an 18‑month pilot, not a one‑off integration sprint. Underestimating this line is the most common reason digital health pilots fail after a promising demo.

**Researcher (£45,000):** Budgeted at 0.5 FTE — appropriate for a feasibility pilot where the app auto‑captures session telemetry and wellbeing scores, leaving the evaluator to focus on protocol, ethics, site liaison, analysis, and the evidence report rather than manual data entry.

**Cloud services (~£11,000):** The POC stores state on‑device only. A multi‑site pilot needs a secure hosted layer on **AWS (eu‑west‑2)** with **MongoDB Atlas** (tenant‑sharded, UK‑pinned), EKS, Redis, S3/CloudFront, researcher exports, audio caching, and uptime monitoring — with GDPR Art. 9 controls and backup in line with care‑setting expectations (~£9,100 over 18 months). Also includes an estimated **£900 Anthropic Claude** subscription for the lead developer (Pro at ~£20/month, with headroom for Max‑tier months during peak streaming/API integration work).

**Tech hardware (£10,000):** Engineering and QA kit for Oscillomind — development Mac(s), test iPads across iOS versions and screen sizes, and spare units for on‑site debugging during the pilot. This is **not** resident deployment hardware; pilot homes run on existing care‑home iPads, while the developer maintains a dedicated test fleet to ship reliable builds.

*Note: clinical outcome claims should be substantiated by the pilot/evaluation. This prototype is pilot‑ready and already captures the data needed to evidence impact. Final figures should be adjusted once streaming provider, cloud vendor, dev hardware quotes, and researcher host institution costs are confirmed. Engineering detail: see [`IMPLEMENTATION_PLAN.md`](./IMPLEMENTATION_PLAN.md).*
