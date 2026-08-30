# Terms of Service

**Effective Date:** 2026-07-03 | **Last Updated:** 2026-07-03
**App:** BikinStiker
**Contact:** support@bikinstiker.example

---


### 1. Acceptance of Terms

By downloading, installing, or using the BikinStiker mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

### 2. Eligibility

You must be at least 13 years old (or the minimum age required in your jurisdiction) to use the App. By using the App, you represent that you meet this age requirement.

### 3. Account Types

#### 3.1 Guest (Anonymous) Account
- On first launch, the App creates an anonymous session automatically.
- Guest users receive 1 starter credit to try the App.
- Guest users can generate stickers but cannot save or share them until they create a registered account.
- Guest stickers, packs, tray icons, and prompt logs are retained only if you upgrade the same anonymous session to a registered account, using a short-lived one-time migration token. Guest content cannot be transferred to a different existing account.

#### 3.2 Registered Account
- You may create an account using your email and password, or via a supported third-party sign-in provider (e.g., Google Sign-In).
- Registered users receive 1 starter credit upon account creation, plus a +4 registration bonus (idempotent) granted automatically by the `grant_registered_bonus()` RPC after sign-up or anonymous upgrade, for a total of 5 starter credits.
- Registered users can save, share, and export generated stickers.

#### 3.3 Third-Party Sign-In
- You may sign in using a third-party OAuth provider such as Google Sign-In.
- Third-party sign-in is subject to the provider's own terms and privacy policy.
- You are responsible for maintaining the security of your third-party account.
- We receive only basic profile information (e.g., name, email, profile photo) from the provider; we do not receive your password.

### 4. Credits and Virtual Currency

#### 4.1 How Credits Work
- Each sticker generation costs 1 credit.
- Credits have no monetary value and cannot be exchanged for cash.
- Credits are granted through: initial account setup (1 starter + 4 registration bonus = 5 total for new registered users), monthly subscription grants, mission rewards, daily check-in streak rewards (mission_reward type), or administrative grants.
- Registration bonus is granted automatically and idempotently via the `grant_registered_bonus()` RPC. If you signed up directly (non-anonymous), you also receive the bonus on first authentication.

#### 4.2 Credit Expiration
- Monthly subscription grants and mission rewards may have an expiration date (typically 30 days).
- Daily check-in rewards expire 30 days after they are granted.
- Expired credits are removed from your balance automatically and the original grant row is marked with `expired_at`.

#### 4.3 Free and Plus Tiers
- **Free tier**: 5 credits monthly grant, access to free presets, 2 pack slots. Wallet cap: 50 credits.
- **Plus tier**: 50 credits monthly grant, access to all presets including Plus-only styles, 20 pack slots. Wallet cap: 50 credits (200 credits if granted administratively).
- Monthly grants are skipped automatically if your current balance is already at or above `tier_cap`. The cap is per wallet, not per month.
- Tier features and limits may change with prior notice.

#### 4.4 Refund on Failed Generation
- If sticker generation fails after your credit has been deducted, the credit is automatically refunded.
- If generation fails before deduction, no credit is charged.

### 5. Sticker Generation

#### 5.1 How It Works
- You select a visual style preset, enter a text description (prompt), and optionally add a caption.
- The App sends your request to our server, which may first enhance your prompt via a text-only reasoning model (Mistral) and then generate a sticker image using one of several AI providers (Pixazo Flux-1-Schnell, Pixazo SDXL Base 1.0, OpenRouter, Gemini, or Pollinations as fallback).
- The generated sticker is a die-cut style image with a transparent background (white outline retained), sized for WhatsApp compatibility.
- Caption text (max 10 characters) can be embedded into the sticker at top or bottom position.

#### 5.2 AI-Generated Content
- Generated stickers are produced by artificial intelligence models. Results may vary and may not exactly match your prompt.
- We do not guarantee that generated content will be unique, free of defects, or free from third-party claims.
- You are responsible for reviewing generated content before using or sharing it.
- Generated content may occasionally contain unintended artifacts or biases inherent to AI technology.

#### 5.3 Prompt and Caption Restrictions
- Your prompts and captions must not contain content that is illegal, harmful, hateful, sexually explicit, defamatory, or that infringes on the rights of others.
- We reserve the right to refuse or remove content that violates these restrictions.
- We may log prompts, prompt enhancement metadata, and provider/model metadata for abuse prevention, service improvement, and diagnostic purposes.

### 6. User Content and License

#### 6.1 Your Prompts
- You retain ownership of the text prompts and captions you submit.
- By submitting prompts, you grant us a limited, non-exclusive license to process, store, and use them solely for the purpose of generating stickers and operating the App.

#### 6.2 Generated Stickers
- You are granted a non-exclusive, worldwide, royalty-free license to use, copy, modify, and distribute generated stickers for personal and commercial purposes, subject to applicable law.
- This license does not extend to the AI models, style descriptors, or the App's underlying technology.
- Generated stickers are AI-produced. You are responsible for ensuring your use complies with applicable laws, including disclosure requirements for AI-generated content.
- This license is subject to applicable laws in your jurisdiction, including any disclosure or labelling requirements for AI-generated content.

### 7. Sticker Packs and WhatsApp Export

#### 7.1 Pack Creation
- You can create sticker packs containing 3 to 30 stickers.
- Each pack has a name, tray icon, and emoji associations.
- Pack slots are limited based on your subscription tier (2 for Free, 20 for Plus).

#### 7.2 WhatsApp Import
- Sticker packs can be exported to WhatsApp via Android's sticker ContentProvider.
- Exported stickers are stored locally on your device and served to WhatsApp through the system's content provider.
- WhatsApp may cache and handle exported stickers according to its own terms and policies.
- We are not responsible for WhatsApp's behavior, changes, or removal of sticker functionality.

#### 7.3 Tray Icon
- The tray icon for your pack is automatically derived from the first sticker's content.
- You may change the tray icon by selecting a different sticker in the pack.

### 8. Advertising

#### 8.1 Google AdMob
- When enabled, the App displays banner ads via Google AdMob. Rewarded video ads are currently used to grant mission credits. Banner placement is opt-in and may be disabled without notice.
- AdMob may collect device information, advertising identifiers, and usage data as described in Google's Privacy Policy.
- Your ad personalization settings may affect which ads are shown.

#### 8.2 Rewarded Ads
- You may choose to watch a rewarded ad to earn additional credits.
- Credits are granted only after the ad provider confirms the reward event occurred.
- Ad availability is not guaranteed; if ads fail to load, no reward is granted.
- You may not attempt to manipulate or exploit the rewarded ad system.

### 9. Anti-Abuse Policy

- We implement rate limiting and abuse prevention measures to protect the service.
- You may not:
  - Attempt to circumvent rate limits or credit restrictions
  - Use automated scripts, bots, or other tools to interact with the App
  - Submit content that is harmful, illegal, or violates the rights of others
  - Attempt to access other users' data or accounts
  - Reverse-engineer, decompile, or disassemble the App
- We reserve the right to suspend, restrict, or terminate accounts that violate these terms.

### 10. Intellectual Property

- The App, including its code, design, logos, and trademarks, is the property of [TO_BE_FILLED_BY_LEGAL] and protected by applicable intellectual property laws.
- You may not copy, modify, distribute, sell, or lease any part of the App without our written consent.
- The visual style descriptors used for sticker generation are proprietary and not disclosed to users.

### 11. Disclaimer of Warranties

THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

WE DO NOT WARRANT THAT:
- THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE
- GENERATED CONTENT WILL MEET YOUR EXPECTATIONS
- THE APP WILL BE COMPATIBLE WITH ALL DEVICES OR OPERATING SYSTEMS
- ADVERTISING OR THIRD-PARTY SERVICES WILL FUNCTION CORRECTLY

### 12. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, [TO_BE_FILLED_BY_LEGAL] SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF DATA, LOSS OF PROFITS, OR BUSINESS INTERRUPTION, ARISING FROM YOUR USE OF THE APP.

OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID TO US IN THE 12 MONTHS PRECEDING THE CLAIM, OR $100 USD, WHICHEVER IS GREATER.

### 13. Termination

- You may terminate your account at any time by contacting us or through the App's account settings.
- We may suspend or terminate your account if you violate these Terms, engage in abusive behavior, or if required by law.
- Upon termination, your right to use the App ceases. Account data is soft-deleted immediately and hard-deleted by our scheduled job after a 30-day grace period. We may retain certain records as described in our Privacy Policy.
- Marketing emails are sent only when you opt in via the Email Marketing toggle in Profile. You may opt out at any time; withdrawal does not affect prior processing.

### 14. Changes to These Terms

- We may update these Terms from time to time.
- Material changes will require your renewed acceptance via the App before you can continue using it.
- Non-material changes may be updated without individual notice.
- The effective date at the top of this document indicates the most recent revision.

### 15. Governing Law

These Terms are governed by the laws of the Republic of Indonesia, without regard to conflict of law principles. Any disputes arising from these Terms shall be resolved in the courts of the Republic of Indonesia, unless otherwise required by applicable consumer protection law.

### 16. Severability

If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.

### 17. Entire Agreement

These Terms, together with our Privacy Policy, constitute the entire agreement between you and [TO_BE_FILLED_BY_LEGAL] regarding the use of the App.

### 18. Contact Us

If you have questions about these Terms, contact us at:

**Email:** support@bikinstiker.example
**Address:** [TO_BE_FILLED_BY_LEGAL]

---

