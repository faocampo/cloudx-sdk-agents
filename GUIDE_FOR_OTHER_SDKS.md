# Implementing AI Agents for SDKs - Guide for iOS, Flutter, and Beyond

**Based on CloudX Android SDK Agent Implementation**

This guide documents the architecture, patterns, and lessons learned from implementing Claude Code agents for the CloudX Android SDK. Use this as a blueprint for creating agents for other SDKs (iOS, Flutter, Unity, React Native, etc.).

---

## Table of Contents

1. [Why AI Agents for SDK Integration](#why-ai-agents-for-sdk-integration)
2. [Architecture Overview](#architecture-overview)
3. [Repository Structure](#repository-structure)
4. [Agent Design Patterns](#agent-design-patterns)
5. [Validation & CI/CD](#validation--cicd)
6. [Cross-Repo Sync Strategy](#cross-repo-sync-strategy)
7. [Publisher Experience](#publisher-experience)
8. [Implementation Checklist](#implementation-checklist)
9. [Lessons Learned](#lessons-learned)

---

## Why AI Agents for SDK Integration

### The Problem

Traditional SDK integration is:
- **Time-consuming:** 4-6 hours for experienced developers
- **Error-prone:** Easy to miss steps, misconfigure settings
- **Context-heavy:** Publishers need to understand ad mediation, fallback logic, privacy compliance
- **Repetitive:** Same integration pattern across thousands of apps

### The Solution: Specialized AI Agents

AI agents reduce integration time to **~20 minutes** by:
- Automating boilerplate code generation
- Implementing best practices automatically
- Validating compliance (GDPR, CCPA, COPPA)
- Preserving existing ad networks as fallback
- Catching build errors early

### Key Metrics (Android Implementation)

- **Integration time:** 4-6 hours → 20 minutes (93% reduction)
- **Error rate:** Significantly reduced (build validation catches issues)
- **Adoption:** Easier onboarding = more integrations
- **Support tickets:** Reduced by automating common issues

---

## Architecture Overview

### Multi-Agent System

We use a **specialized agent architecture** where each agent handles one aspect of integration:

```
Publisher (via Claude Code)
    │
    ├──► Integration Agent       (Implementation)
    ├──► Auditor Agent           (Validation)
    ├──► Build Verifier Agent    (Testing)
    ├──► Privacy Checker Agent   (Compliance)
    └──► Maintainer Agent        (SDK Dev Tool)
```

### Why Multiple Agents?

1. **Separation of concerns:** Each agent is an expert in one domain
2. **Reusability:** Agents can be invoked independently or orchestrated
3. **Maintainability:** Updates to one agent don't break others
4. **Model optimization:** Use expensive models (Sonnet) only where needed, cheaper models (Haiku) for simple tasks

### Two-Repository Model

```
SDK Repository (e.g., cloudx-ios-sdk)
├── SDK source code
├── Maintainer agent only
└── SDK_VERSION.yaml (source of truth)

Agent Repository (e.g., cloudx-ios-agents)
├── Publisher-facing agents
├── Documentation
├── Installation scripts
└── Validation scripts
```

**Why split?**
- **Versioning independence:** Update agent docs without SDK releases
- **Distribution:** Agents can be installed/updated separately
- **Discoverability:** Dedicated repo for AI integration tooling
- **Clean separation:** SDK devs vs. publisher tools

---

## Repository Structure

### Agent Repository (`cloudx-[platform]-agents`)

Recommended structure:

```
cloudx-[platform]-agents/
├── README.md                          # Landing page with quick start
├── CLAUDE.md                          # Claude Code guidance (optional but helpful)
│
├── .claude/agents/                    # Agent definitions (markdown files)
│   ├── cloudx-[platform]-integrator.md
│   ├── cloudx-[platform]-auditor.md
│   ├── cloudx-[platform]-build-verifier.md
│   └── cloudx-[platform]-privacy-checker.md
│
├── docs/                              # Publisher documentation
│   ├── SETUP.md                       # Installation & getting started
│   ├── INTEGRATION_GUIDE.md           # Comprehensive integration examples
│   └── ORCHESTRATION.md               # Multi-agent workflows
│
├── scripts/                           # Automation scripts
│   ├── install.sh                     # Agent installer for publishers
│   ├── validate_agent_apis.sh         # Validates agent docs vs SDK
│   └── check_api_coverage.sh          # API coverage analysis
│
├── examples/ (optional)               # Example integration projects
│   ├── basic-integration/
│   └── admob-fallback/
│
├── SDK_VERSION.yaml                   # Tracks compatible SDK versions & APIs
│
└── .github/workflows/
    └── validate-sync.yml              # CI: validates agent docs on PRs
```

### SDK Repository (e.g., `cloudx-ios-sdk`)

Minimal agent footprint:

```
cloudx-[platform]-sdk/
├── [SDK source code]
│
├── .claude/
│   ├── README.md                      # Points to agent repo
│   ├── agents/
│   │   └── cloudx-[platform]-agent-maintainer.md  # Maintainer agent only
│   └── maintenance/
│       ├── README.md                  # Maintenance docs
│       ├── UPDATE_WORKFLOW.md         # How to sync agents
│       └── SDK_VERSION.yaml           # Source of truth for API tracking
│
├── scripts/
│   ├── sync_to_agent_repo.sh          # Helper for cross-repo sync
│   └── validate_critical_apis.sh      # Validates SDK APIs
│
└── .github/workflows/
    ├── [existing SDK workflows]
    ├── validate-maintainer-agent.yml  # Validates maintainer agent
    └── sync-agent-repo.yml            # Detects API changes, triggers sync
```

---

## Agent Design Patterns

### 1. Integration Agent (`cloudx-[platform]-integrator.md`)

**Purpose:** Implements SDK integration with fallback to existing ad networks

**Capabilities:**
- Add SDK dependencies (CocoaPods, Swift Package Manager, Gradle, pub.dev)
- Initialize SDK in app lifecycle (AppDelegate, Application class, main.dart)
- Create ad loading managers with try-CloudX-first, fallback-on-error logic
- Update existing ad code to use new mediation layer
- Preserve existing ad network setup as backup

**Tools:** Read, Write, Edit, Grep, Glob, Bash

**Model:** Sonnet (needs reasoning for code integration)

**Example Prompt Pattern:**
```
Use @agent-cloudx-ios-integrator to integrate CloudX SDK with AdMob fallback
```

**Key Sections in Agent Doc:**
- When to use this agent
- Integration workflow (step-by-step)
- Fallback logic implementation
- Code examples for each ad format
- Error handling patterns
- Common issues & solutions

### 2. Auditor Agent (`cloudx-[platform]-auditor.md`)

**Purpose:** Validates that fallback paths remain intact after integration

**Capabilities:**
- Verify existing ad SDK initialization code is present
- Confirm fallback triggers in error callbacks
- Check state flags and tracking hooks
- Identify broken or missing fallback code paths
- Validate ad network configurations

**Tools:** Read, Grep, Glob (no Write/Edit - validation only)

**Model:** Sonnet (needs reasoning to understand code flow)

**Example Prompt Pattern:**
```
Use @agent-cloudx-ios-auditor to verify my AdMob fallback still works
```

**Key Sections:**
- What gets audited
- Fallback path checklist
- Validation criteria
- Common failure modes
- How to fix broken fallbacks

### 3. Build Verifier Agent (`cloudx-[platform]-build-verifier.md`)

**Purpose:** Runs builds and reports compilation errors with actionable fixes

**Capabilities:**
- Execute platform-specific build commands (xcodebuild, gradle, flutter build)
- Parse build output for errors
- Provide file:line references for failures
- Suggest fixes for common build issues
- Re-run builds after fixes

**Tools:** Bash, Read

**Model:** Haiku (simple task, faster execution)

**Example Prompt Pattern:**
```
Use @agent-cloudx-ios-build-verifier to build the project
```

**Platform-Specific Commands:**
```bash
# iOS
xcodebuild -workspace MyApp.xcworkspace -scheme MyApp clean build

# Android
./gradlew build

# Flutter
flutter build ios --no-codesign
flutter build apk
```

**Key Sections:**
- Build commands by platform
- Error parsing logic
- Common build errors & fixes
- Troubleshooting guide

### 4. Privacy Checker Agent (`cloudx-[platform]-privacy-checker.md`)

**Purpose:** Validates GDPR, CCPA, COPPA compliance

**Capabilities:**
- Verify SDK privacy API usage (consent, age restriction)
- Check IAB consent string handling (TCF, USPrivacy, GPP)
- Ensure privacy signals pass to all ad SDKs
- Validate Info.plist / AndroidManifest.xml declarations
- Flag privacy violations

**Tools:** Read, Grep, Glob

**Model:** Haiku (pattern matching task)

**Example Prompt Pattern:**
```
Use @agent-cloudx-ios-privacy-checker to audit privacy compliance
```

**Platform-Specific Checks:**
```
iOS:
- Info.plist: NSUserTrackingUsageDescription, GADApplicationIdentifier
- ATTrackingManager.requestTrackingAuthorization usage
- CloudXPrivacy API calls

Android:
- AndroidManifest.xml permissions
- SharedPreferences for IAB strings
- CloudXPrivacy API calls

Flutter:
- Permission declarations in both iOS/Android
- Privacy API usage in Dart code
```

**Key Sections:**
- Privacy regulations overview
- Platform requirements
- SDK privacy APIs
- IAB compliance
- Common violations

### 5. Maintainer Agent (`cloudx-[platform]-agent-maintainer.md`)

**Purpose:** FOR SDK DEVELOPERS - Syncs agent docs when SDK APIs change

**Capabilities:**
- Detect SDK API changes (class renames, method signature changes)
- Update agent docs in external agent repo
- Sync SDK_VERSION.yaml
- Run validation scripts
- Generate sync report for PR

**Tools:** Read, Write, Edit, Grep, Glob, Bash

**Model:** Sonnet (complex reasoning & code analysis)

**Lives in:** SDK repo only (not agent repo)

**Example Prompt Pattern:**
```
Use @agent-cloudx-ios-agent-maintainer to sync agent repo with SDK changes
```

**Cross-Repo Sync Mode:**
- Checks if agent repo exists at sibling directory
- Compares SDK_VERSION.yaml files
- Updates affected agent docs
- Creates branch and commits
- Generates PR description

**Key Sections:**
- When to use (after API changes)
- Workflow (discovery, update, validate, report)
- Cross-repository sync mode
- Environment variables
- Common update scenarios

---

## Validation & CI/CD

### Agent Repository CI

**Workflow:** `.github/workflows/validate-sync.yml`

```yaml
name: Validate Agent Sync

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest  # or macos-latest for iOS
    steps:
      - uses: actions/checkout@v4

      - name: Validate agent APIs
        run: bash scripts/validate_agent_apis.sh

      - name: Check SDK version
        run: grep -q "sdk_version:" SDK_VERSION.yaml
```

**What it validates:**
- Agent files exist
- No deprecated API patterns in docs
- Agent docs reference current API classes
- Common integration patterns present
- (Optional) Full validation against SDK source if available

### SDK Repository CI

**Workflow 1:** `.github/workflows/validate-maintainer-agent.yml`

```yaml
name: Validate Maintainer Agent

on:
  push:
    branches: [main, develop]
    paths:
      - 'sdk/**'
      - '.claude/**'
  pull_request:
    branches: [main, develop]

jobs:
  validate:
    steps:
      - name: Validate SDK_VERSION.yaml sync
        run: |
          # Check YAML version matches SDK version in package file
          # (Package.swift, build.gradle, pubspec.yaml, etc.)

      - name: Check maintainer agent exists
        run: |
          # Ensure maintainer agent file present

      - name: Detect API changes
        run: |
          # Comment on PR if API changes detected
```

**Workflow 2:** `.github/workflows/sync-agent-repo.yml`

```yaml
name: Sync Agent Repository

on:
  push:
    branches: [main]
    paths:
      - 'sdk/path/to/public/apis/**'

jobs:
  check-changes:
    # Detect API changes
    # Comment on PR to remind about syncing
```

---

## Cross-Repo Sync Strategy

### Manual Sync (Recommended for Start)

1. SDK dev makes API changes
2. CI detects changes, comments on PR
3. After merge, dev manually runs maintainer agent
4. Maintainer agent creates PR in agent repo
5. Agent repo CI validates
6. Manual review and merge

**Pros:** Full control, easier to debug
**Cons:** Requires manual step

### Automated Sync (Advanced)

Use GitHub Actions to automatically invoke maintainer agent and create PR.

**Requirements:**
- GitHub PAT with repo access
- Claude Code CLI in CI environment
- Automated PR creation via gh CLI

**Example (conceptual):**
```yaml
- name: Run maintainer agent
  env:
    GITHUB_TOKEN: ${{ secrets.AGENT_REPO_PAT }}
    AGENT_REPO_URL: https://github.com/cloudx-io/cloudx-ios-agents
  run: |
    # Clone agent repo
    # Run maintainer agent
    # Create PR
    gh pr create --repo cloudx-io/cloudx-ios-agents --title "Sync with SDK v$VERSION" --body-file sync_report.md
```

---

## Publisher Experience

### Installation

**One-line install:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cloudx-io/cloudx-[platform]-agents/main/scripts/install.sh)
```

**What it does:**
- Checks Claude Code is installed
- Installs agents to `~/.claude/agents/` (global) or `.claude/agents/` (local)
- Validates installation
- Prints usage instructions

### Usage Patterns

**Full Integration:**
```
1. Use @agent-cloudx-ios-integrator to integrate CloudX SDK with AdMob fallback
2. Use @agent-cloudx-ios-auditor to verify fallback paths are correct
3. Use @agent-cloudx-ios-build-verifier to build the project
4. Use @agent-cloudx-ios-privacy-checker to validate privacy compliance
```

**Quick Fix:**
```
1. Use @agent-cloudx-ios-auditor to find what's broken
2. Use @agent-cloudx-ios-integrator to fix the issues
3. Use @agent-cloudx-ios-build-verifier to verify fixes compile
```

### Documentation

**Essential Docs:**
1. **SETUP.md** - Installation, first integration, troubleshooting
2. **INTEGRATION_GUIDE.md** - Comprehensive examples for all ad formats
3. **ORCHESTRATION.md** - Multi-agent workflows, advanced patterns

**Keep it actionable:**
- Start with "Quick Start" (5 minutes to first result)
- Provide copy-paste examples
- Include screenshots/GIFs where helpful
- Link to relevant SDK docs

---

## Implementation Checklist

### Phase 1: Planning (1 week)

- [ ] Review this guide and Android implementation
- [ ] Identify SDK integration pain points
- [ ] Define agent scope (which ad formats, which fallback networks)
- [ ] Choose agent names (follow `cloudx-[platform]-[purpose]` pattern)
- [ ] Plan repository structure

### Phase 2: Agent Repository Setup (1 week)

- [ ] Create `cloudx-[platform]-agents` repository
- [ ] Set up directory structure (see [Repository Structure](#repository-structure))
- [ ] Create README.md with quick start
- [ ] Add CLAUDE.md (optional but helpful)
- [ ] Create SDK_VERSION.yaml template

### Phase 3: Agent Development (2-3 weeks)

- [ ] Write Integration Agent
  - Define capabilities and workflow
  - Write step-by-step integration logic
  - Add code examples for all ad formats
  - Add fallback implementation patterns
  - Test on sample projects

- [ ] Write Auditor Agent
  - Define validation criteria
  - Add fallback path checks
  - Document common failure modes
  - Test validation accuracy

- [ ] Write Build Verifier Agent
  - Add platform-specific build commands
  - Implement error parsing
  - Add common error fixes
  - Test with intentional build errors

- [ ] Write Privacy Checker Agent
  - Define privacy requirements
  - Add platform-specific checks
  - Document compliance criteria
  - Test with non-compliant code

### Phase 4: Documentation (1 week)

- [ ] Write SETUP.md
  - Installation instructions
  - First integration walkthrough
  - Troubleshooting section

- [ ] Write INTEGRATION_GUIDE.md
  - Comprehensive examples
  - All ad formats
  - All fallback scenarios

- [ ] Write ORCHESTRATION.md
  - Multi-agent workflows
  - Common scenarios
  - Advanced patterns

### Phase 5: Validation & CI (1 week)

- [ ] Create `validate_agent_apis.sh`
  - Check agent files exist
  - Validate API references
  - Check for deprecated patterns

- [ ] Create `check_api_coverage.sh` (optional)
  - Analyze API coverage
  - Report missing APIs

- [ ] Set up agent repo CI workflow
  - Validate on PRs
  - Run validation scripts

- [ ] Create install.sh script
  - Agent installation
  - Validation
  - Usage instructions

### Phase 6: SDK Integration (1 week)

- [ ] Create Maintainer Agent in SDK repo
  - API change detection
  - Agent doc update logic
  - Cross-repo sync capability

- [ ] Create SDK_VERSION.yaml in SDK repo
  - Current SDK version
  - API signatures
  - Agent file references

- [ ] Set up SDK CI workflows
  - Validate maintainer agent
  - Detect API changes
  - Comment on PRs

- [ ] Create sync scripts
  - sync_to_agent_repo.sh
  - validate_critical_apis.sh

### Phase 7: Testing (1-2 weeks)

- [ ] Internal testing
  - Test full integration workflow
  - Test all agents independently
  - Test multi-agent orchestration
  - Test on multiple projects

- [ ] Beta testing
  - Invite 3-5 friendly publishers
  - Collect feedback
  - Fix issues
  - Iterate on documentation

- [ ] CI/CD testing
  - Trigger all workflows
  - Verify validation works
  - Test PR comments
  - Test sync process

### Phase 8: Launch (1 week)

- [ ] Public announcement
  - Blog post
  - SDK documentation update
  - Social media
  - Email to active publishers

- [ ] Monitor adoption
  - Track installations
  - Monitor GitHub issues
  - Collect feedback

- [ ] Support
  - Respond to issues quickly
  - Update docs based on feedback
  - Iterate on agents

**Total timeline:** 8-12 weeks from start to launch

---

## Lessons Learned (from Android Implementation)

### What Worked Well

1. **Separate agent repository**
   - Clean separation of concerns
   - Independent versioning
   - Easier distribution
   - Publishers can install without cloning SDK

2. **Multiple specialized agents**
   - Each agent is focused and maintainable
   - Can be invoked independently
   - Easier to update one aspect without breaking others

3. **Validation scripts with graceful degradation**
   - Agent repo CI works without SDK source
   - Provides helpful error messages
   - Suggests fixes when validation fails

4. **Cross-repo sync with maintainer agent**
   - SDK changes automatically trigger reminder
   - Maintainer agent handles complexity
   - PR-based workflow for review

5. **Comprehensive documentation**
   - SETUP.md gets publishers started quickly
   - INTEGRATION_GUIDE.md answers deep questions
   - ORCHESTRATION.md shows advanced patterns

### What We'd Do Differently

1. **Start with examples directory**
   - Add example projects showing agent output from day 1
   - Makes testing easier
   - Publishers can see expected results

2. **Automate more of the sync process**
   - Initial implementation was too manual
   - GitHub Actions can trigger maintainer agent automatically
   - Reduces maintenance burden

3. **Version agents independently**
   - Add semantic versioning to agent repo
   - Track breaking changes separately from SDK
   - Allow publishers to pin agent versions

4. **Add telemetry early**
   - Track which agents are used most
   - Identify pain points
   - Measure integration time improvement

5. **Create agent marketplace entry**
   - Make agents discoverable in Claude Code marketplace
   - Provide ratings/reviews
   - Increase adoption

### Common Pitfalls to Avoid

1. **Don't put agents in SDK repo long-term**
   - Creates bloat
   - Couples versioning
   - Harder for publishers to discover

2. **Don't skip validation**
   - Agents will drift out of sync with SDK
   - Publishers will hit errors
   - Maintenance burden increases

3. **Don't make agents too complex**
   - Each agent should do ONE thing well
   - If agent is >500 lines, consider splitting
   - Complexity makes maintenance harder

4. **Don't ignore cross-platform patterns**
   - iOS developers know Android terms
   - Flutter developers know native terms
   - Use consistent naming and patterns

5. **Don't forget the publisher journey**
   - Test on real projects, not toy examples
   - Consider various app architectures
   - Handle edge cases gracefully

### Success Metrics to Track

1. **Adoption metrics:**
   - Agent installations (from install.sh)
   - Agent invocations (if telemetry available)
   - GitHub stars/forks of agent repo

2. **Quality metrics:**
   - Integration time (before/after)
   - Error rate (build failures, runtime crashes)
   - Support tickets related to integration

3. **Engagement metrics:**
   - GitHub issues opened (feature requests, bugs)
   - PR contributions from community
   - Documentation page views

4. **Business metrics:**
   - SDK adoption rate increase
   - Time-to-revenue for new publishers
   - Publisher satisfaction scores

---

## Platform-Specific Considerations

### iOS (`cloudx-ios-agents`)

**Unique aspects:**
- CocoaPods vs. Swift Package Manager
- AppDelegate vs. SwiftUI App struct
- Objective-C vs. Swift codebases
- UIKit vs. SwiftUI views
- Info.plist requirements
- ATTrackingTransparency framework

**Build commands:**
```bash
xcodebuild -workspace MyApp.xcworkspace -scheme MyApp clean build
# or
swift build
```

**Package managers:**
```ruby
# CocoaPods
pod 'CloudX-iOS-SDK', '~> 1.0'
```

```swift
// Swift Package Manager
.package(url: "https://github.com/cloudx-io/cloudx-ios-sdk", from: "1.0.0")
```

### Flutter (`cloudx-flutter-agents`)

**Unique aspects:**
- pubspec.yaml dependencies
- Platform-specific code in iOS/Android folders
- main.dart entry point
- Widget tree structure
- Platform channels for native code
- Both iOS and Android considerations

**Build commands:**
```bash
flutter pub get
flutter build ios --no-codesign
flutter build apk
flutter build appbundle
```

**Package spec:**
```yaml
dependencies:
  cloudx_flutter_sdk: ^1.0.0
```

### Unity (`cloudx-unity-agents`)

**Unique aspects:**
- Asset Store vs. UPM (Unity Package Manager)
- C# scripting
- GameObject hierarchy
- Editor vs. runtime code
- Multi-platform builds (iOS, Android)
- Custom inspector windows

**Build commands:**
```bash
# Unity CLI builds
/Applications/Unity/Hub/Editor/[version]/Unity.app/Contents/MacOS/Unity -quit -batchmode -buildTarget iOS -executeMethod BuildScript.BuildIOS
```

### React Native (`cloudx-rn-agents`)

**Unique aspects:**
- npm/yarn dependencies
- Native module linking (iOS + Android)
- JavaScript/TypeScript codebase
- Metro bundler
- Expo vs. bare React Native

**Build commands:**
```bash
npm install
npx react-native run-ios
npx react-native run-android
```

---

## Resources

### CloudX Android Implementation (Reference)

- **Agent Repo:** https://github.com/cloudx-io/cloudx-sdk-agents
- **SDK Repo:** https://github.com/cloudx-io/cloudx-android

### Claude Code Documentation

- **Official Docs:** https://docs.claude.com/claude-code
- **Agent Specification:** https://docs.claude.com/claude-code/agents

### Contact

For questions about implementing agents for your SDK:
- **Email:** mobile@cloudx.io
- **GitHub Discussions:** https://github.com/cloudx-io/cloudx-sdk-agents/discussions

---

## Appendix: Agent Frontmatter Template

Each agent is a markdown file with YAML frontmatter:

```markdown
---
name: cloudx-[platform]-[purpose]
description: [When to use this agent - critical for auto-routing]
tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet  # or haiku, opus
---

[Agent instructions go here]
```

**Example:**
```markdown
---
name: cloudx-ios-integrator
description: Use this agent to integrate CloudX SDK into iOS projects with AdMob fallback
tools: Read, Write, Edit, Grep, Glob, Bash
model: sonnet
---

You are a CloudX iOS integration specialist...
```

---

**Good luck implementing agents for your SDK! 🚀**

*Questions? Open an issue or discussion in the cloudx-sdk-agents repo.*
