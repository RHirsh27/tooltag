# Processly

> Turn messy notes into clear processes instantly.

Processly is a SwiftUI + SwiftData iOS 16+ application that turns raw voice and text into structured processes and playbooks. This repository contains the MVP scaffold with architecture, dependency stubs, and TODOs required to complete the product specification.

## Project Structure

- App/ – application entry point, routing, and theming.
- Domain/ – models and service abstractions (Speech, LLM, Quota, Export, IAP, Metrics, Network).
- Data/ – repositories and seed data.
- UI/ – feature views organized by flow.
- Utilities/ – shared helpers and extensions.
- Resources/ – assets, localization stubs, App Store metadata placeholders.
- Tests/ – unit and UI test suites with starter coverage for critical logic.

## Running the App

1. Open the workspace via xed . or open Package.swift in Xcode 15.
2. Select the Processly iOS app target and run on an iOS 16+ simulator or device.
3. Grant microphone and speech permissions when recording.

## Feature Flags & Configuration

- LLM endpoint and API key configuration TODO in DefaultLLMService.
- Crash/analytics SDK wiring TODO in AppDelegate and MetricsService.
- Whisper support (alternate ASR engine) placeholder in SettingsView.

## In-App Purchases

| Product ID        | Type        | Notes                               |
|-------------------|-------------|--------------------------------------|
| pro_monthly_799 | Auto-renew  | Unlocks Pro entitlements.            |
| pro_yearly_4999 | Auto-renew  | Feature parity, emphasized in UI.    |

Entitlements mapped:

- pro_unlimited – removes finalize quota.
- export_premium – unlocks DOCX/Markdown export and removes watermark.

Update IAPService once StoreKit products are live and receipt validation keys are available.

## Testing

- Unit tests in Tests/Unit cover JSON validation, quota resets, export handling, and PostProcessor TODOs.
- UI automation placeholder in Tests/UITests for the capture ? generate ? edit ? finalize ? export flow.
- Run with swift test.

## App Store Assets

Placeholder prompts live in Sources/Resources/AppStore/Metadata.md. Replace with final copy and imagery before submission.

## Policies

- Privacy Policy: https://processly.example.com/privacy (TODO: replace with production URL)
- Terms of Service: https://processly.example.com/terms (TODO: replace with production URL)
