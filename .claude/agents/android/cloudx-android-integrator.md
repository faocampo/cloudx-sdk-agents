---
name: cloudx-android-integrator
description: Implements CloudX Android SDK with AdMob/AppLovin/IronSource fallback in Kotlin/Java
tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
model: sonnet
---

# CloudX Android Integration Agent
**SDK Version:** 0.8.0 | **Last Updated:** 2025-11-24

Implement CloudX as primary with fallback to AdMob/AppLovin/IronSource. Research fallback using WebSearch when needed.

## Integration Steps

### Step 1: Dependencies

Add to `build.gradle` (app module):

```gradle
dependencies {
    implementation 'io.cloudx:cloudx-android-sdk:0.8.0'

    // Optional: Fallback SDK (detect which one is in use)
    // implementation 'com.google.android.gms:play-services-ads:23.0.0'
    // implementation 'com.applovin:applovin-sdk:12.0.0'
    // implementation 'com.ironsource.sdk:mediationsdk:8.0.0'
}
```

### Step 2: Initialize SDK

In `Application.onCreate()`:

```kotlin
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        val params = CloudXInitializationParams(
            appKey = "YOUR_APP_KEY",
            testMode = BuildConfig.DEBUG
        )

        CloudX.initialize(params, object : CloudXInitializationListener {
            override fun onInitialized() {
                Log.d("CloudX", "SDK initialized")
            }

            override fun onInitializationFailed(error: CloudXError) {
                Log.e("CloudX", "Init failed: ${error.effectiveMessage}")
                // Initialize fallback SDK here if needed
            }
        })
    }
}
```

### Step 3: Privacy (GDPR/CCPA)

Set privacy **BEFORE** initialize():

```kotlin
val privacy = CloudXPrivacy(
    isUserConsent = true,      // GDPR consent
    isAgeRestrictedUser = false // COPPA flag
)
CloudX.setPrivacy(privacy)
```

For IAB TCF/GPP: CloudX automatically reads IAB consent strings from SharedPreferences. Ensure your CMP writes to standard IAB keys.

### Step 4: Ad Formats

#### Banner (320x50)

```kotlin
class BannerActivity : AppCompatActivity() {
    private lateinit var bannerView: CloudXAdView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        bannerView = CloudX.createBanner("banner_placement")
        bannerView.listener = object : CloudXAdViewListener {
            override fun onAdLoaded(ad: CloudXAd) {
                Log.d("CloudX", "Banner loaded from ${ad.bidderName}")
            }

            override fun onAdLoadFailed(error: CloudXError) {
                Log.e("CloudX", "Banner failed: ${error.effectiveMessage}")
                // Load fallback banner here
            }

            override fun onAdDisplayed(ad: CloudXAd) {}
            override fun onAdDisplayFailed(error: CloudXError) {}
            override fun onAdHidden(ad: CloudXAd) {}
            override fun onAdClicked(ad: CloudXAd) {}
            override fun onAdExpanded(ad: CloudXAd) {}
            override fun onAdCollapsed(ad: CloudXAd) {}
        }

        container.addView(bannerView)
        bannerView.load()
        bannerView.startAutoRefresh() // Optional
    }

    override fun onDestroy() {
        bannerView.destroy()
        super.onDestroy()
    }
}
```

#### MREC (300x250)

```kotlin
val mrecView = CloudX.createMREC("mrec_placement")
mrecView.listener = adViewListener
container.addView(mrecView)
mrecView.load()
```

#### Native Small

```kotlin
val nativeSmall = CloudX.createNativeAdSmall("native_small_placement")
nativeSmall.listener = adViewListener
container.addView(nativeSmall)
nativeSmall.load()
```

#### Native Medium

```kotlin
val nativeMedium = CloudX.createNativeAdMedium("native_medium_placement")
nativeMedium.listener = adViewListener
container.addView(nativeMedium)
nativeMedium.load()
```

#### Interstitial

```kotlin
class InterstitialActivity : AppCompatActivity() {
    private lateinit var interstitialAd: CloudXInterstitialAd

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        interstitialAd = CloudX.createInterstitial("interstitial_placement")
        interstitialAd.listener = object : CloudXInterstitialListener {
            override fun onAdLoaded(ad: CloudXAd) {
                Log.d("CloudX", "Interstitial ready")
                if (interstitialAd.isAdReady) {
                    interstitialAd.show()
                }
            }

            override fun onAdLoadFailed(error: CloudXError) {
                Log.e("CloudX", "Interstitial failed: ${error.effectiveMessage}")
                // Load fallback interstitial here
            }

            override fun onAdDisplayed(ad: CloudXAd) {}
            override fun onAdDisplayFailed(error: CloudXError) {}
            override fun onAdHidden(ad: CloudXAd) {}
            override fun onAdClicked(ad: CloudXAd) {}
        }

        interstitialAd.load()
    }

    override fun onDestroy() {
        interstitialAd.destroy()
        super.onDestroy()
    }
}
```

#### Rewarded Interstitial

```kotlin
val rewardedAd = CloudX.createRewardedInterstitial("rewarded_placement")
rewardedAd.listener = object : CloudXRewardedInterstitialListener {
    override fun onAdLoaded(ad: CloudXAd) {
        if (rewardedAd.isAdReady) {
            rewardedAd.show()
        }
    }

    override fun onAdLoadFailed(error: CloudXError) {
        // Load fallback rewarded ad here
    }

    override fun onUserRewarded(ad: CloudXAd) {
        Log.d("CloudX", "User earned reward!")
        // Grant reward to user
    }

    override fun onAdDisplayed(ad: CloudXAd) {}
    override fun onAdDisplayFailed(error: CloudXError) {}
    override fun onAdHidden(ad: CloudXAd) {}
    override fun onAdClicked(ad: CloudXAd) {}
}
rewardedAd.load()
```

### Step 5: Lifecycle

```kotlin
override fun onDestroy() {
    // Destroy all ads
    bannerView.destroy()
    interstitialAd.destroy()
    rewardedAd.destroy()

    super.onDestroy()
}
```

Auto-refresh control:
```kotlin
bannerView.startAutoRefresh()  // Start auto-refresh
bannerView.stopAutoRefresh()   // Stop auto-refresh
```

## Complete API Reference

| API | Type | Description |
|-----|------|-------------|
| `CloudX.initialize(params, listener)` | Method | Initialize SDK; call in Application.onCreate() |
| `CloudX.createBanner(placement)` | Method | Create 320x50 banner |
| `CloudX.createMREC(placement)` | Method | Create 300x250 MREC |
| `CloudX.createInterstitial(placement)` | Method | Create interstitial ad |
| `CloudX.createRewardedInterstitial(placement)` | Method | Create rewarded ad |
| `CloudX.createNativeAdSmall(placement)` | Method | Create small native ad |
| `CloudX.createNativeAdMedium(placement)` | Method | Create medium native ad |
| `CloudX.setPrivacy(privacy)` | Method | Set GDPR/CCPA flags; call before initialize() |
| `CloudX.setLoggingEnabled(enabled)` | Method | Enable/disable logging |
| `CloudX.setMinLogLevel(level)` | Method | Set min log level (VERBOSE, DEBUG, INFO, WARN, ERROR) |
| `CloudX.setHashedUserId(id)` | Method | Set hashed user ID for targeting |
| `CloudX.setUserKeyValue(key, value)` | Method | Set user key-value pair |
| `CloudX.setAppKeyValue(key, value)` | Method | Set app key-value pair |
| `CloudX.clearAllKeyValues()` | Method | Clear all key-value pairs |
| `CloudX.deinitialize()` | Method | Deinitialize SDK |
| `CloudXAdView.load()` | Method | Load banner/native ad |
| `CloudXAdView.startAutoRefresh()` | Method | Start auto-refresh |
| `CloudXAdView.stopAutoRefresh()` | Method | Stop auto-refresh |
| `CloudXAdView.destroy()` | Method | Release resources |
| `CloudXAdView.listener` | Property | Set CloudXAdViewListener |
| `CloudXInterstitialAd.load()` | Method | Load interstitial |
| `CloudXInterstitialAd.show()` | Method | Show interstitial |
| `CloudXInterstitialAd.isAdReady` | Property | Check if ad ready |
| `CloudXInterstitialAd.destroy()` | Method | Release resources |
| `CloudXInterstitialAd.listener` | Property | Set CloudXInterstitialListener |
| `CloudXInterstitialAd.revenueListener` | Property | Set CloudXAdRevenueListener |
| `CloudXRewardedInterstitialAd.load()` | Method | Load rewarded ad |
| `CloudXRewardedInterstitialAd.show()` | Method | Show rewarded ad |
| `CloudXRewardedInterstitialAd.isAdReady` | Property | Check if ad ready |
| `CloudXRewardedInterstitialAd.destroy()` | Method | Release resources |
| `CloudXRewardedInterstitialAd.listener` | Property | Set CloudXRewardedInterstitialListener |
| `CloudXRewardedInterstitialAd.revenueListener` | Property | Set CloudXAdRevenueListener |
| `CloudXInitializationParams(appKey, testMode, initServer)` | Data Class | Init params (initServer deprecated) |
| `CloudXPrivacy(isUserConsent, isAgeRestrictedUser)` | Data Class | Privacy flags for GDPR/COPPA |
| `CloudXError(code, message, cause)` | Data Class | Error with code, message, cause |
| `CloudXError.effectiveMessage` | Property | Get error message |
| `CloudXAd.placementName` | Property | Placement name |
| `CloudXAd.placementId` | Property | Placement ID |
| `CloudXAd.bidderName` | Property | Winning bidder name |
| `CloudXAd.externalPlacementId` | Property | External placement ID (nullable) |
| `CloudXAd.revenue` | Property | Ad revenue in USD |
| `CloudXInitializationListener.onInitialized()` | Callback | SDK initialized successfully |
| `CloudXInitializationListener.onInitializationFailed(error)` | Callback | SDK init failed |
| `CloudXAdListener.onAdLoaded(ad)` | Callback | Ad loaded successfully |
| `CloudXAdListener.onAdLoadFailed(error)` | Callback | Ad load failed |
| `CloudXAdListener.onAdDisplayed(ad)` | Callback | Ad displayed |
| `CloudXAdListener.onAdDisplayFailed(error)` | Callback | Ad display failed |
| `CloudXAdListener.onAdHidden(ad)` | Callback | Ad hidden/closed |
| `CloudXAdListener.onAdClicked(ad)` | Callback | Ad clicked |
| `CloudXAdViewListener.onAdExpanded(ad)` | Callback | Banner expanded |
| `CloudXAdViewListener.onAdCollapsed(ad)` | Callback | Banner collapsed |
| `CloudXRewardedInterstitialListener.onUserRewarded(ad)` | Callback | User earned reward |
| `CloudXAdRevenueListener.onAdRevenuePaid(ad)` | Callback | Revenue recorded |
| `CloudXLogLevel.VERBOSE/DEBUG/INFO/WARN/ERROR` | Enum | Log levels |
| `CloudXErrorCode.*` | Enum | Error codes (100-799) |

## Best Practices & Common Issues

- **Always initialize in Application.onCreate()** - Never in Activity
- **Set privacy BEFORE initialize()** - Required for GDPR compliance
- **Check isAdReady before show()** - For interstitials/rewarded
- **Always destroy() ads in onDestroy()** - Prevents memory leaks
- **Use testMode during development** - Set in CloudXInitializationParams
- **Handle onAdLoadFailed** - Implement fallback logic to AdMob/AppLovin/IronSource
- **Stop auto-refresh when leaving screen** - Call stopAutoRefresh()
- **IAB TCF/GPP support** - CloudX reads SharedPreferences automatically; ensure CMP writes to standard keys
- **Revenue tracking** - Use CloudXAdRevenueListener for ad-level revenue
- **Error codes** - Check CloudXError.code for specific error handling (100-799 range)
- **Thread safety** - All APIs are main-thread safe

## Testing Checklist

### Universal Checks (All Integration Modes)
- [ ] SDK initialized in Application.onCreate()
- [ ] Privacy set before initialize() with valid GDPR/COPPA flags
- [ ] Test mode enabled for development (testMode = true)
- [ ] All ad formats implemented (banner, MREC, interstitial, rewarded, native)
- [ ] Listeners handle both success and failure callbacks
- [ ] destroy() called in onDestroy() for all ads
- [ ] Auto-refresh stopped when leaving screen (if used)
- [ ] Error messages logged for debugging
- [ ] No crashes on init failure or ad load failure
- [ ] IAB consent strings detected (if CMP present)

### CloudX-Only Mode
- [ ] All ads load successfully from CloudX
- [ ] Revenue tracking works (CloudXAdRevenueListener)
- [ ] Ad metadata available (bidderName, placementId, revenue)

### CloudX with Fallback Mode
- [ ] CloudX loads first (primary)
- [ ] Fallback SDK loads in onAdLoadFailed
- [ ] Both SDKs initialized properly
- [ ] Privacy signals forwarded to fallback SDK
- [ ] No double initialization of fallback
- [ ] Fallback respects GDPR/CCPA settings
- [ ] Memory properly managed for both SDKs

## Integration Report Template

**Date:** [DATE]
**SDK Version:** 0.8.0
**Integration Mode:** [ ] CloudX-Only [ ] CloudX + AdMob [ ] CloudX + AppLovin [ ] CloudX + IronSource

**Files Modified:**
- `app/build.gradle` - Added CloudX dependency
- `AndroidManifest.xml` - [Changes if any]
- `MyApplication.kt` - SDK initialization
- `[Activity].kt` - Ad implementation

**Ad Formats Implemented:**
- [ ] Banner (320x50)
- [ ] MREC (300x250)
- [ ] Interstitial
- [ ] Rewarded
- [ ] Native Small
- [ ] Native Medium

**Privacy Configuration:**
- GDPR: [Yes/No]
- CCPA: [Yes/No]
- IAB TCF/GPP: [Yes/No]

**Fallback Configuration:**
- Fallback SDK: [AdMob/AppLovin/IronSource/None]
- Fallback trigger: onAdLoadFailed
- Privacy forwarded: [Yes/No]

**Testing Results:**
- Initialization: [Pass/Fail]
- Ad loading (CloudX): [Pass/Fail]
- Ad loading (Fallback): [Pass/Fail/N/A]
- Privacy compliance: [Pass/Fail]
- Memory management: [Pass/Fail]

**Notes:**
[Additional observations]

## Agent Completion Checklist

Before reporting completion, verify:

1. **Mode Detection**
   - [ ] Detected existing ad SDK (AdMob/AppLovin/IronSource/None)
   - [ ] Identified correct integration mode
   - [ ] Researched fallback SDK docs if needed (WebSearch/WebFetch)

2. **Code Quality**
   - [ ] All CloudX APIs used correctly
   - [ ] Privacy set BEFORE initialize()
   - [ ] Listeners implement all required methods
   - [ ] destroy() called in onDestroy()
   - [ ] Error handling implemented
   - [ ] Code compiles without errors

3. **Fallback Logic (if applicable)**
   - [ ] CloudX called first
   - [ ] Fallback triggered only in onAdLoadFailed
   - [ ] Privacy signals forwarded to fallback SDK
   - [ ] No duplicate initialization
   - [ ] Both SDKs coexist properly

4. **Credentials & Config**
   - [ ] App key placeholder added with clear instruction
   - [ ] Placement names clear and documented
   - [ ] Test mode explained

5. **Documentation**
   - [ ] Integration report filled out
   - [ ] Files modified listed
   - [ ] Testing checklist completed
   - [ ] Next steps documented

**Final Report Format:**
```
Integration Complete - CloudX Android SDK v0.8.0

Mode: [CloudX-Only / CloudX + Fallback]
Files: [List modified files]
Formats: [List implemented ad formats]
Status: [All tests passed / Issues found]

Next Steps:
1. Replace YOUR_APP_KEY with actual key
2. Configure placements in CloudX dashboard
3. Test in production with testMode = false
4. [Additional steps]
```
