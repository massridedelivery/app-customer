# Audit Report: Onboarding Feature

**Target Feature**: `lib/features/onboarding/`  
**Audit Date**: May 2026  
**Auditor**: Gemini CLI  

---

## 1. Compliance Checklist (Based on `.ai_rules/rule.md`)

| Rule | Status | Observations |
| :--- | :---: | :--- |
| **No StatefulWidget** | ❌ **Fail** | `onboarding_screen.dart` uses `StatefulWidget` for page index and `PageController`. |
| **No Logic in Widgets** | ❌ **Fail** | `onboarding_screen.dart` contains local page data and navigation logic in `_onNextPressed`. |
| **Logic in Controller** | ❌ **Fail** | No Riverpod Controller exists for the onboarding feature. |
| **Clean Architecture** | ⚠️ **Partial** | Only `presentation` layer exists. No `domain` or `data` layers, even for simple state like completion. |
| **const Constructors** | ✅ **Pass** | Standard widgets use `const` where appropriate. |
| **PascalCase Filenames** | ✅ **Pass** | All files use `snake_case`. |

---

## 2. Detailed Findings

### 2.1 UI vs. Logic Separation
- **`onboarding_screen.dart`**: This is a classic "Smart Widget" that has been implemented as a `StatefulWidget`. It holds the list of onboarding pages, tracks the current index, and handles navigation. According to project rules, this logic should reside in a `StateNotifier` or `Notifier` (Riverpod Controller).
- **`location_setup_screen.dart`**: Contains the `_completeOnboarding` method directly in the UI file. While it uses Riverpod, the business logic of marking onboarding as complete and deciding where to navigate next should be inside a Controller.

### 2.2 State Management
- The feature is largely "static" but lacks a centralized state for the onboarding flow. 
- Tracking whether a user has seen onboarding is handled by `AppStorage` directly in the UI (`location_setup_screen.dart`).

### 2.3 Widget Hierarchy
- **`onboarding_page.dart`**: Correctly implemented as a `StatelessWidget` (Dumb Widget).
- **`splash_screen.dart`**: Uses `ConsumerStatefulWidget`. This is acceptable under the rule: *"AVOID StatefulWidget at all costs unless implementing highly complex animations"*, as it uses an `AnimationController`. However, the navigation logic `_navigateToNextScreen` should ideally be triggered by a controller state change.

---

## 3. Recommended Fixes

1.  **Create Onboarding Controller**:
    - Path: `lib/features/onboarding/presentation/controllers/onboarding_controller.dart`
    - Logic: Move page data, index tracking, and `completeOnboarding` logic here.
2.  **Refactor `onboarding_screen.dart`**:
    - Change to `ConsumerWidget`.
    - Read page data and index from the controller.
    - Invoke controller methods for "Next" and "Page Change".
3.  **Refactor `location_setup_screen.dart`**:
    - Move `_completeOnboarding` logic into the new `OnboardingController`.
4.  **Data Layer**:
    - If the onboarding flow becomes more complex (e.g., fetching steps from an API), add `data` and `domain` layers. For now, a controller is the priority.

---

## 4. Final Verdict
The Onboarding feature is functional but **violates the core architectural mandates** of the project regarding `StatefulWidget` usage and logic placement. It requires refactoring to align with the **Controller-State** pattern and **Riverpod** standards defined in the repository.
