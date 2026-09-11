# Copilot Instructions for Subway iOS App

Purpose: Give AI coding agents the minimum, specific project knowledge to be productive without generic boilerplate.

## Architecture & Core Patterns
- UIKit + MVVM + ReactiveSwift/ReactiveCocoa. ViewModels expose `MutableProperty/Action`; Views & Controllers bind via closures or `observe` in `bindViewModel()` (see `DashboardNavController`, `DashboardViewController`, `AppDelegate`).
- Dependency Injection via Swinject (`SwinjectStoryboard.defaultContainer`). Avoid creating singletons manually; resolve injected services in controllers or view models. Core registrations live under `Subway/Sdk/` and related implementation folders (e.g. `SdkManagerImpl.swift`). When adding a service:
  1. Define a protocol in a feature or global folder.
  2. Provide concrete impl (suffix `Impl`).
  3. Register in the central container extension (search for existing `register(` calls) instead of ad‑hoc `Assembler` usage.
- Navigation is centralized in feature-specific NavControllers (e.g. `DashboardNavController`) which wire closures from child VCs to routing methods. Follow existing closure callback pattern for new flows.
- Region/market variants (NA, Finland, TUKI, Germany) are handled by build targets, Info.plists (`Source/*-Info.plist`), conditional compilation flags (`#if FINLAND`), and Fastlane lanes. Do not hardcode market-specific logic—prefer feature flags or existing mappers.
- Constants are modularized (`Constants+*.swift`). Add new keys in an existing extension file that matches the concern (e.g. analytics -> `Constants+Analytics.swift`). Avoid expanding `Constants.swift` directly unless foundational.
- Feature flags: use LaunchDarkly + `FeatureFlagMapper` (protocol in Source) rather than branching on raw keys.
- Network & state: Session/state flows through a resolved `Session` object (see `AppDelegate`). Avoid instantiating `Session` directly.
- Animations / transitions use custom animator classes (`RightToLeftAnimator`, `CrossFadeAnimator`) invoked in nav controllers. Reuse these instead of adding ad-hoc transitions.

## Key Directories
- `Source/Presentation/` UI layer segmented by feature (Menu, OrderSummary, PaymentMethods, Rewards, etc.). Keep new views within the appropriate domain folder.
- `Source/Data/` (and related mappers/handlers like `StoreUpdater`, `CartUpdater`) for data fetch/update orchestration. Place new persistence/network coordination here.
- `Source/Global` and `Helpers/` for cross-cutting helpers. Prefer extending existing helpers before adding new global utilities.
- `fastlane/` CI/CD automation; reflects supported configuration names and schemes.
- `cicd/` contains export options and environment provisioning artifacts—mirror patterns when adding new lanes or build artifacts.

## Build & Tooling
- Uses CocoaPods (Swift 5.9, iOS 15). Run with Bundler to ensure version lock:
  ```bash
  bundle install
  bundle exec pod install
  open Subway.xcworkspace
  ```
- Linting via `SwiftLint` only on specified configurations (see Podfile). If adding new build configs and you expect lint, include them in the SwiftLint pod `:configurations` list.
- Multiple Fastlane lanes per environment (e.g. `NA_DEV`, `NA_QE`, `NA_DEV1`, etc.). Match scheme + configuration naming exactly when introducing new schemes.
- OneTrust version toggled by `ENV['PRODUCTION_BUILD']`; do not inline different CMP versions—extend helper `version_for_debug_or_release` if logic changes.

## External SDK Integration
- Adobe SDK modules (AEP*) initialized via `SdkManager` (`sdkManager.initializeSDKs`). Add new Adobe-related init steps inside `SdkManager`, not `AppDelegate`. Consent gating flows through `OneTrustManager` → `SdkManagerImpl` grouping arrays (`essentialSDKs`, `performanceSDKs`, `targetingSDKs`). Place new SDK managers into the proper array based on consent tier and implement `BaseSdkManager` methods.
- Firebase: Dynamic Links only for certain markets (`#if FINLAND` etc.). Maintain conditional imports consistent with existing patterns.
- Analytics / Deeplinks: Branch and Adobe events triggered from navigation or action closures; replicate event emissions near existing analogous flows.
- Feature flags via LaunchDarkly—never gate UI with raw environment conditionals if a flag exists.

## Navigation & Flow Conventions
- ViewControllers are created via static factory like `SomeViewController.newInstance()`. Match this pattern instead of calling bare init/storyboard instantiation.
- Routing functions typically mutate navigation stack after optional pre-processing (e.g., ensuring store selection). Follow `showXView()` naming.
- Pass data forward through strongly typed method params or closure captures, not singletons.
 - When wiring interactions, prefer closure properties on the child VC set by the NavController (see numerous closures in `DashboardNavController.showDashboardView()`). Keep naming consistent: verb + context (e.g. `startOrderPressed`, `viewBagPressed`).

## Analytics & Events
- Adobe analytics constants referenced via `Constants.AdobeAnalyticsEvents.*`; do not inline literal strings. Add new page names/sections inside the existing constants extension rather than new enums.
- State vs action: Use `trackState` style invocations for page/screen impressions (see usages like `sendWarningDataToAnalytics(state:pageName:section:...)`). Use dedicated actions/events for button taps or flows; search for similar call patterns before introducing new ones.
- Always include `section` consistent with tab or domain (e.g. `dashboard`, `menu`, `accountSec`) to maintain segmentation.
- Branch / deep links: persist and resolve through existing handlers in `AppDelegate` before routing; emit analytics after successful resolution, not before.
- When adding a new user flow, identify entry + exit events and mirror parameter sets (pageLink, pageName, section) from the closest existing feature.

## Reactive Usage
- Prefer `Action<Input, Output, Error>` for user-triggered or lifecycle-triggered side effects (API calls, persistence). Expose it on the ViewModel; NEVER start it directly in the view initializer—trigger via closures or notification observers (`NotificationCenter.default.reactive.notifications`).
- Throttle duplicates: always guard with `if !action.isExecuting.value { action.apply(input).start() }` (pattern in `DashboardNavController` for offers refresh).
- Use `MutableProperty` for UI state that needs two‑way binding (text fields, toggles) and `Property` (or computed) for derived/read-only state.
- Bind UI -> ViewModel by assigning inside closures (e.g. button tap closure sets a `MutableProperty` or starts an `Action`); bind ViewModel -> UI via `producer.startWithValues { [weak self] ... }` and add the disposable to the controller's `CompositeDisposable`.
- Always capture `[weak self]` inside reactive callbacks in controllers to avoid retain cycles; ViewModels generally do not capture controllers so they can use strong self.
- Schedulers: default to main thread for UI side effects (`start(on:)` only when doing background work beforehand). If you map/flatMap expensive work, push it to a background `QueueScheduler` then deliver back on main before touching UIKit.
- Cancellation: keep reference to produced `Disposable` when starting long-lived producers (timers, polling) and dispose in `deinit` or when view disappears.
- Avoid chaining side effects inside `map`; use `on(value:)` or `flatMap(.concat)` for sequencing to keep transformations pure.
- When combining multiple properties for UI enablement, use `SignalProducer.combineLatest(...)` then `map` to a Bool rather than storing extra mutable flags.
- For one-off events (like showing a toast) prefer a `Signal`/`Observer` pair rather than abusing a `MutableProperty` that resets.

## Adding New Features
1. Create feature folder under appropriate domain in `Presentation` and pair with needed view model(s).
2. Add constants, analytics keys, deeplink identifiers in the relevant `Constants+` extension file.
3. Inject dependencies via Swinject registration (locate existing container setup—extend there rather than inline instantiation).
4. Expose user interactions through closures; wire them in the parent NavController.
5. Emit analytics & feature flag checks by mirroring similar existing flows.

## Do / Avoid
- Do reuse existing mappers (`*Mapper.swift`) before adding new translation layers.
- Do not bypass `Session` for auth/state; always read/write via its reactive properties.
- Do not introduce new global singletons—prefer DI + protocol abstraction.
- Avoid hardcoding region logic in UI—prefer capability flags or existing protocols.

## When Unsure
Search for a similar feature folder and replicate structure (e.g. see `OrderSummary/`, `PaymentMethods/`). Keep naming & closure patterns consistent.
