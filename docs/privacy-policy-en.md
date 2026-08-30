# Privacy Policy

**Effective Date:** 2026-07-03 | **Last Updated:** 2026-07-03
**App:** BikinStiker
**Contact:** privacy@bikinstiker.example

---


### 1. Overview

This Privacy Policy describes how [TO_BE_FILLED_BY_LEGAL] ("we", "us", or "our") collects, uses, and protects your personal information when you use the BikinStiker mobile application (the "App"). By using the App, you agree to the practices described in this policy.

### 2. Data We Collect

#### 2.1 Account Data
- **Email and password** — when you create an account via email/password sign-up.
- **Google account information** (when available) — your name, email address, and profile photo, as provided by Google Sign-In via Supabase Auth. We do not receive your Google password.
- **Anonymous session data** — a device-level anonymous session is created automatically on first launch. This is linked to a server-generated user ID, not your personal identity.

#### 2.2 Sticker and Generation Data
- **Text prompts and captions** — the text you enter to generate stickers, including any caption text and its position.
- **Preset and style metadata** — which visual style you selected.
- **Generated images** — the sticker images created by AI on your behalf, stored in private cloud storage with access limited to your account.
- **Generation history** — timestamps, preset names, prompt text, generation status, and provider/model metadata for diagnostic purposes.
- **Prompt enhancement logs** — when reasoning enhancement is applied, we log the original prompt length, success/failure status, cache hit status, and latency. The enhanced prompt is sent to the image generation provider.

#### 2.3 Credits, Wallet, and Subscription Data
- **Credit balance** — your current in-app credit balance.
- **Transaction records** — credit grants, deductions, refunds, mission rewards, and subscription grants, including expiration dates.
- **Subscription tier** — your current tier (e.g., free or plus) and active subscription period.
- **Mission progress** — missions you have completed and the credits earned.
- **Daily check-in streak records** — the date of your last claim and your current consecutive-day streak count.

#### 2.4 Anti-Bot and Abuse Prevention Data
- **Hashed IP address** — a non-reversible hash of your IP address for rate-limiting and abuse detection.
- **Usage telemetry** — generation attempts, blocked requests, and retry metadata, used to protect the service.

#### 2.5 Advertising Data
- **Rewarded video ads (active)** — when you choose to watch a rewarded ad to earn credits, Google AdMob processes the ad delivery and reward event. Google may collect device information, advertising identifiers, and usage data as described in Google's Privacy Policy.
- **Banner ads (when enabled)** — when banner ads are enabled, Google AdMob may collect your advertising ID, device model, OS version, app interactions, diagnostic data, and approximate location, depending on your device settings, ad personalization consent, and Google's policies. Banner placement is opt-in and may be disabled at any time.

#### 2.6 Local Device Data
- **Image cache** — generated stickers may be cached locally on your device to improve loading performance.
- **Sticker pack export cache** — when you export a sticker pack to WhatsApp, temporary files may be stored locally on your device.

#### 2.7 Guest Migration Tokens
- When you upgrade from a guest session to a registered account, a short-lived one-time token (`guest_migration_tokens`) is created to transfer your generated stickers, packs, tray icons, and prompt logs.
- Tokens are hashed at rest, expire automatically (typically within minutes of issuance), and are not shared with third parties.
- Tokens are consumed exactly once by the migration RPC and are then invalidated.

### 3. How We Use Your Data

| Purpose | Data Used | Legal Basis |
|---|---|---|
| Provide and operate the App | Account data, sticker data, wallet data | Performance of contract |
| Generate AI-powered stickers | Text prompts, captions, preset selection, enhanced prompt | Performance of contract |
| Manage credits, subscriptions, and missions | Wallet, subscription, mission, and daily check-in data | Performance of contract |
| Prevent abuse and maintain service security | Anti-bot events, hashed IP, usage telemetry | Legitimate interest |
| Display personalized advertising (when enabled) | AdMob identifiers, device info, rewarded ad events | Consent (where required by law) |
| Improve the service and diagnose issues | Generation logs, prompt enhancement logs, provider metadata, diagnostic data | Legitimate interest |
| Send policy or service updates | Contact information if provided | Legitimate interest / Consent |

### 4. Third-Party Processors

We share your data with the following third-party service providers as necessary to operate the App:

| Provider | Purpose | Privacy Policy |
|---|---|---|
| **Supabase** | Authentication, database, cloud storage, serverless functions | https://supabase.com/privacy |
| **Google (AdMob)** | Rewarded video ads, banner ads (when enabled), fraud prevention | https://policies.google.com/privacy |
| **Google Sign-In** | OAuth authentication (when available) | https://policies.google.com/privacy |
| **Pixazo** | Server-side sticker image generation (Flux-1-Schnell, SDXL Base 1.0; free tier, rate-limited) | https://pixazo.ai/privacy |
| **OpenRouter** | Server-side sticker image generation (paid fallback) | https://openrouter.ai/privacy |
| **Gemini** | Server-side sticker image generation (paid fallback) | https://ai.google.dev/privacy |
| **Pollinations** | Server-side sticker image generation (unauthenticated fallback) | https://pollinations.ai/privacy |
| **Mistral** | Text-only prompt enhancement before image generation (not used for image generation) | https://mistral.ai/privacy |
| **WhatsApp (on-device)** | Importing generated sticker packs into WhatsApp | https://www.whatsapp.com/privacy |

Server-side API keys for AI providers are never exposed to the App. They are stored and managed exclusively on our backend servers.

### 5. Data Retention

| Data Category | Retention Period |
|---|---|
| Account and authentication data | Retained while your account is active; deleted upon account deletion request |
| Sticker generation history | Retained while your account is active or until manually deleted |
| Credits and transaction records | Retained for 3 years for audit purposes |
| Subscription records | Retained for 3 years for audit purposes |
| Anti-bot and abuse logs | Retained for up to 12 months |
| Prompt enhancement logs | Retained for up to 12 months |
| Daily check-in streak records | Retained while your account is active |
| Guest migration tokens | Short-lived (minutes); invalidated immediately after consumption |
| Local device cache | Stored until cleared by you or by app/OS cleanup |
| Legal consent record | Retained indefinitely as audit proof |
| Advertising data | Handled by Google per their retention policies |

### 6. Your Rights (GDPR / UU PDP)

Depending on your jurisdiction, you may have the following rights regarding your personal data:

- **Access** — request a copy of the personal data we hold about you.
- **Correction** — request correction of inaccurate or incomplete data.
- **Deletion** — request deletion of your personal data, subject to legal retention obligations.
- **Withdrawal of Consent** — withdraw consent for data processing where consent is the legal basis (e.g., advertising, marketing emails). Withdrawal does not affect the lawfulness of processing that occurred before withdrawal.
- **Data Portability** — request your data in a structured, commonly used, machine-readable format.
- **Restriction / Objection** — request restriction of processing or object to processing in certain circumstances.
- **Lodge a Complaint** — file a complaint with your local data protection authority.

To exercise your rights, contact us at privacy@bikinstiker.example. We will respond within 30 days of receiving your request.

### 7. Children's Privacy

The App is not intended for children under the age of 13 (or the applicable minimum age in your jurisdiction). We do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us immediately so we can delete it.

### 8. International Data Transfers

Your data may be processed in countries outside your jurisdiction, including where Supabase, Google, Pixazo, OpenRouter, Gemini, Pollinations, or Mistral operate their infrastructure. These transfers are protected by appropriate safeguards, including standard contractual clauses where required by applicable law.

### 9. Security

We implement industry-standard security measures to protect your data:

- **Row Level Security (RLS)** — database access is restricted to your own records.
- **Private storage with signed URLs** — sticker files are stored in private buckets; temporary signed URLs expire after a limited time.
- **Server-side API key management** — AI provider credentials are never exposed to the client app.
- **Hashed migration tokens** — guest migration tokens are stored as one-way hashes and expire within minutes.
- **Secure authentication** — provided by Supabase Auth with industry-standard protocols.

However, no method of transmission or storage is 100% secure. We cannot guarantee absolute security of your data.

### 10. Changes to This Policy

We may update this Privacy Policy from time to time. Material changes will require renewed consent via the App. Non-material changes may be updated without notification. The effective date at the top of this document indicates the most recent revision.

### 11. Contact Us

If you have questions about this Privacy Policy or wish to exercise your data rights, contact us at:

**Email:** privacy@bikinstiker.example
**Address:** [TO_BE_FILLED_BY_LEGAL]

---

