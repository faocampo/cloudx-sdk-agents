---
name: cloudx-android-integrator
description: Implements CloudX Android SDK v0.8.0 with AdMob/AppLovin/IronSource fallback in Kotlin/Java
tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
model: sonnet
---

# CloudX Android Integration Agent
**SDK Version:** 0.8.0 | **Last Updated:** 2025-11-24

Implement CloudX as primary ad network with fallback to AdMob/AppLovin/IronSource. Research fallback SDK integration using WebSearch when needed.

## Integration Steps

### Step 1: Add Dependencies

```gradle
dependencies {
    implementation("io.cloudx:cloudx-android-sdk:0.8.0")

    // Fallback SDKs (research versions using WebSearch if needed)
    implementation("com.google.android.gms:play-services-ads:23.0.0") // AdMob
    // or implementation("com.applovin:applovin-sdk:12.x.x") // AppLovin
    // or implementation("com.ironsource.sdk:mediationsdk:8.x.x") // IronSource
}
```

### Step 2: Initialize SDK

```kotlin
// In Application.onCreate() or MainActivity
CloudX.initialize(
    CloudXInitializationParams(
        appKey = "your-cloudx-app-key",
        testMode = true // Set false for production
    ),
    object : CloudXInitializationListener {
        override fun onInitialized() {
            Log.d("CloudX", "SDK initialized successfully")
        }

        override fun onInitializationFailed(error: CloudXError) {
            Log.e("CloudX", "Init failed: ${error.effectiveMessage}")
            // Initialize fallback SDK (AdMob/AppLovin/IronSource)
        }
    }
)
```

### Step 3: Privacy (GDPR/CCPA)

Call **before** initialization:

```kotlin
CloudX.setPrivacy(
    CloudXPrivacy(
        isUserConsent = true,  // GDPR consent
        isAgeRestrictedUser = false // COPPA flag
    )
)
```

**IAB TCF/GPP Support:** CloudX automatically reads IAB Transparency & Consent Framework (TCF) and Global Privacy Platform (GPP) strings from SharedPreferences if available. Ensure your CMP (Consent Management Platform) writes standard IAB strings before SDK initialization.

### Step 4: Ad Formats

#### Banner (320x50)

```kotlin
class MainActivity : AppCompatActivity() {
    private var cloudxBanner: CloudXAdView? = null
    private var admobBanner: AdView? = null // Fallback

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Try CloudX first
        cloudxBanner = CloudX.createBanner("banner-placement")
        cloudxBanner?.listener = object : CloudXAdViewListener {
            override fun onAdLoaded(ad: CloudXAd) {
                Log.d("Banner", "CloudX loaded: ${ad.bidderName}")
            }

            override fun onAdLoadFailed(error: CloudXError) {
                Log.e("Banner", "CloudX failed: ${error.effectiveMessage}")
                loadAdMobBanner() // Fallback
            }

            override fun onAdDisplayed(ad: CloudXAd) {}
            override fun onAdDisplayFailed(error: CloudXError) {}
            override fun onAdHidden(ad: CloudXAd) {}
            override fun onAdClicked(ad: CloudXAd) {}
            override fun onAdExpanded(ad: CloudXAd) {}
            override fun onAdCollapsed(ad: CloudXAd) {}
        }

        bannerContainer.addView(cloudxBanner)
        cloudxBanner?.load()
    }

    private fun loadAdMobBanner() {
        // Research AdMob banner implementation using WebSearch if needed
        admobBanner = AdView(this).apply {
            adUnitId = "ca-app-pub-xxx/yyy"
            setAdSize(AdSize.BANNER)
            adListener = object : AdListener() {
                override fun onAdLoaded() {
                    bannerContainer.removeView(cloudxBanner)
                    bannerContainer.addView(admobBanner)
                }
            }
            loadAd(AdRequest.Builder().build())
        }
    }

    override fun onDestroy() {
        cloudxBanner?.destroy()
        admobBanner?.destroy()
        super.onDestroy()
    }
}
```

#### MREC (300x250)

```kotlin
val mrec = CloudX.createMREC("mrec-placement")
mrec.listener = object : CloudXAdViewListener {
    override fun onAdLoaded(ad: CloudXAd) {}
    override fun onAdLoadFailed(error: CloudXError) {
        // Fallback to AdMob/AppLovin/IronSource MREC
    }
    override fun onAdDisplayed(ad: CloudXAd) {}
    override fun onAdDisplayFailed(error: CloudXError) {}
    override fun onAdHidden(ad: CloudXAd) {}
    override fun onAdClicked(ad: CloudXAd) {}
    override fun onAdExpanded(ad: CloudXAd) {}
    override fun onAdCollapsed(ad: CloudXAd) {}
}
container.addView(mrec)
mrec.load()
```

#### Interstitial

```kotlin
class InterstitialManager(private val activity: Activity) {
    private var cloudxInterstitial: CloudXInterstitialAd? = null
    private var admobInterstitial: InterstitialAd? = null // Fallback

    fun load() {
        cloudxInterstitial = CloudX.createInterstitial("interstitial-placement")
        cloudxInterstitial?.listener = object : CloudXInterstitialListener {
            override fun onAdLoaded(ad: CloudXAd) {
                Log.d("Interstitial", "CloudX ready")
            }

            override fun onAdLoadFailed(error: CloudXError) {
                Log.e("Interstitial", "CloudX failed, loading AdMob")
                loadAdMobInterstitial()
            }

            override fun onAdDisplayed(ad: CloudXAd) {}
            override fun onAdDisplayFailed(error: CloudXError) {}
            override fun onAdHidden(ad: CloudXAd) {
                // Reload for next show
                load()
            }
            override fun onAdClicked(ad: CloudXAd) {}
        }
        cloudxInterstitial?.load()
    }

    fun show() {
        when {
            cloudxInterstitial?.isAdReady == true -> cloudxInterstitial?.show()
            admobInterstitial != null -> admobInterstitial?.show(activity)
            else -> Log.e("Interstitial", "No ad ready")
        }
    }

    private fun loadAdMobInterstitial() {
        // Research AdMob interstitial implementation using WebSearch
        com.google.android.gms.ads.interstitial.InterstitialAd.load(
            activity,
            "ca-app-pub-xxx/yyy",
            AdRequest.Builder().build(),
            object : InterstitialAdLoadCallback() {
                override fun onAdLoaded(ad: com.google.android.gms.ads.interstitial.InterstitialAd) {
                    admobInterstitial = ad
                }
            }
        )
    }

    fun destroy() {
        cloudxInterstitial?.destroy()
        cloudxInterstitial = null
        admobInterstitial = null
    }
}
```

#### Rewarded Interstitial

```kotlin
val rewarded = CloudX.createRewardedInterstitial("rewarded-placement")
rewarded.listener = object : CloudXRewardedInterstitialListener {
    override fun onAdLoaded(ad: CloudXAd) {}

    override fun onAdLoadFailed(error: CloudXError) {
        // Fallback to AdMob/AppLovin/IronSource rewarded
    }

    override fun onAdDisplayed(ad: CloudXAd) {}
    override fun onAdDisplayFailed(error: CloudXError) {}
    override fun onAdHidden(ad: CloudXAd) {}
    override fun onAdClicked(ad: CloudXAd) {}

    override fun onUserRewarded(ad: CloudXAd) {
        Log.d("Rewarded", "User earned reward!")
        // Grant reward to user
    }
}
rewarded.load()

// Later
if (rewarded.isAdReady) {
    rewarded.show()
}
```

#### Native Ads

```kotlin
// Small Native (compact size)
val nativeSmall = CloudX.createNativeAdSmall("native-small-placement")
nativeSmall.listener = object : CloudXAdViewListener {
    override fun onAdLoaded(ad: CloudXAd) {}
    override fun onAdLoadFailed(error: CloudXError) {
        // Fallback to AdMob/AppLovin/IronSource native
    }
    override fun onAdDisplayed(ad: CloudXAd) {}
    override fun onAdDisplayFailed(error: CloudXError) {}
    override fun onAdHidden(ad: CloudXAd) {}
    override fun onAdClicked(ad: CloudXAd) {}
    override fun onAdExpanded(ad: CloudXAd) {}
    override fun onAdCollapsed(ad: CloudXAd) {}
}
container.addView(nativeSmall)
nativeSmall.load()

// Medium Native (larger size)
val nativeMedium = CloudX.createNativeAdMedium("native-medium-placement")
// Same listener setup as above
container.addView(nativeMedium)
nativeMedium.load()
```

### Step 5: Lifecycle Management

```kotlin
// Banner/Native auto-refresh
banner.startAutoRefresh() // Uses server-configured interval
banner.stopAutoRefresh()  // Stop refreshing

// Destroy all ads in onDestroy()
override fun onDestroy() {
    banner?.destroy()
    interstitial?.destroy()
    rewarded?.destroy()
    super.onDestroy()
}
```

### Step 6: Optional - Advanced Features

#### Revenue Tracking

```kotlin
interstitial.revenueListener = object : CloudXAdRevenueListener {
    override fun onAdRevenuePaid(ad: CloudXAd) {
        Log.d("Revenue", "Earned: $${ad.revenue} from ${ad.bidderName}")
        // Send to analytics (Firebase, Adjust, etc.)
    }
}
```

#### User/App Key-Values

```kotlin
CloudX.setHashedUserId("hashed-user-id-123")
CloudX.setUserKeyValue("level", "10")
CloudX.setAppKeyValue("version", "1.2.3")
CloudX.clearAllKeyValues()
```

#### Logging

```kotlin
CloudX.setLoggingEnabled(true)
CloudX.setMinLogLevel(CloudXLogLevel.DEBUG)
```

## Complete API Reference

| Category | API | Description |
|----------|-----|-------------|
| **Core** | `CloudX.initialize(CloudXInitializationParams, CloudXInitializationListener?)` | Initialize SDK (required first) |
| | `CloudX.deinitialize()` | Shutdown SDK |
| | `CloudX.setPrivacy(CloudXPrivacy)` | Set GDPR/CCPA flags (call before init) |
| **Ad Creation** | `CloudX.createBanner(String): CloudXAdView` | Create 320x50 banner |
| | `CloudX.createMREC(String): CloudXAdView` | Create 300x250 MREC |
| | `CloudX.createInterstitial(String): CloudXInterstitialAd` | Create interstitial |
| | `CloudX.createRewardedInterstitial(String): CloudXRewardedInterstitialAd` | Create rewarded ad |
| | `CloudX.createNativeAdSmall(String): CloudXAdView` | Create small native ad |
| | `CloudX.createNativeAdMedium(String): CloudXAdView` | Create medium native ad |
| **Banner/Native** | `CloudXAdView.load()` | Load ad |
| | `CloudXAdView.startAutoRefresh()` | Enable auto-refresh |
| | `CloudXAdView.stopAutoRefresh()` | Disable auto-refresh |
| | `CloudXAdView.destroy()` | Clean up resources |
| | `CloudXAdView.listener: CloudXAdViewListener?` | Set listener |
| **Interstitial** | `CloudXInterstitialAd.load()` | Load ad |
| | `CloudXInterstitialAd.show()` | Display ad |
| | `CloudXInterstitialAd.isAdReady: Boolean` | Check if ready |
| | `CloudXInterstitialAd.destroy()` | Clean up |
| | `CloudXInterstitialAd.listener: CloudXInterstitialListener?` | Set listener |
| | `CloudXInterstitialAd.revenueListener: CloudXAdRevenueListener?` | Set revenue listener |
| **Rewarded** | `CloudXRewardedInterstitialAd.load()` | Load ad |
| | `CloudXRewardedInterstitialAd.show()` | Display ad |
| | `CloudXRewardedInterstitialAd.isAdReady: Boolean` | Check if ready |
| | `CloudXRewardedInterstitialAd.destroy()` | Clean up |
| | `CloudXRewardedInterstitialAd.listener: CloudXRewardedInterstitialListener?` | Set listener |
| | `CloudXRewardedInterstitialAd.revenueListener: CloudXAdRevenueListener?` | Set revenue listener |
| **Logging** | `CloudX.setLoggingEnabled(Boolean)` | Enable/disable logs |
| | `CloudX.setMinLogLevel(CloudXLogLevel)` | Set log level |
| **User Data** | `CloudX.setHashedUserId(String)` | Set hashed user ID |
| | `CloudX.setUserKeyValue(String, String)` | Add user key-value |
| | `CloudX.setAppKeyValue(String, String)` | Add app key-value |
| | `CloudX.clearAllKeyValues()` | Clear all key-values |

### Data Classes

| Class | Properties | Description |
|-------|------------|-------------|
| `CloudXInitializationParams` | `appKey: String`<br>`testMode: Boolean = false` | SDK initialization config |
| `CloudXPrivacy` | `isUserConsent: Boolean?`<br>`isAgeRestrictedUser: Boolean?` | GDPR/COPPA privacy flags |
| `CloudXError` | `code: CloudXErrorCode`<br>`message: String?`<br>`cause: Throwable?`<br>`effectiveMessage: String` | Error information |
| `CloudXAd` | `placementName: String`<br>`placementId: String`<br>`bidderName: String`<br>`externalPlacementId: String?`<br>`revenue: Double` | Ad metadata |

### Enums

| Enum | Values | Description |
|------|--------|-------------|
| `CloudXLogLevel` | `VERBOSE(0)`, `DEBUG(1)`, `INFO(2)`, `WARN(3)`, `ERROR(4)` | Log level priority |
| `CloudXErrorCode` | **Init (100-199):** `NOT_INITIALIZED`, `INITIALIZATION_IN_PROGRESS`, `NO_ADAPTERS_FOUND`, `INITIALIZATION_TIMEOUT`, `INVALID_APP_KEY`, `SDK_DISABLED`<br>**Network (200-299):** `NETWORK_ERROR`, `NETWORK_TIMEOUT`, `INVALID_RESPONSE`, `SERVER_ERROR`, `CLIENT_ERROR`<br>**Loading (300-399):** `NO_FILL`, `INVALID_REQUEST`, `INVALID_PLACEMENT`, `LOAD_TIMEOUT`, `LOAD_FAILED`, `INVALID_AD`, `TOO_MANY_REQUESTS`, `REQUEST_CANCELLED`, `ADS_DISABLED`<br>**Display (400-499):** `AD_NOT_READY`, `AD_ALREADY_DISPLAYED`, `AD_EXPIRED`, `INVALID_VIEW_CONTROLLER`, `DISPLAY_FAILED`<br>**Config (500-599):** `INVALID_AD_UNIT`, `PERMISSION_DENIED`, `UNSUPPORTED_AD_FORMAT`, `INVALID_BANNER_VIEW`, `INVALID_NATIVE_VIEW`<br>**Adapter (600-699):** `ADAPTER_UNEXPECTED_ERROR`, `ADAPTER_INITIALIZATION_ERROR`, `ADAPTER_INVALID_SERVER_EXTRAS`, `ADAPTER_NO_CONNECTION`, `ADAPTER_NO_FILL`, `ADAPTER_SERVER_ERROR`, `ADAPTER_TIMEOUT`, `ADAPTER_INVALID_LOAD_STATE`, `ADAPTER_INVALID_CONFIGURATION`<br>**General (700-799):** `UNEXPECTED_ERROR` | Categorized error codes |

### Listeners

| Listener | Methods | Description |
|----------|---------|-------------|
| `CloudXInitializationListener` | `onInitialized()`<br>`onInitializationFailed(CloudXError)` | SDK init callbacks |
| `CloudXAdListener` | `onAdLoaded(CloudXAd)`<br>`onAdLoadFailed(CloudXError)`<br>`onAdDisplayed(CloudXAd)`<br>`onAdDisplayFailed(CloudXError)`<br>`onAdHidden(CloudXAd)`<br>`onAdClicked(CloudXAd)` | Base ad callbacks |
| `CloudXAdViewListener` | Extends `CloudXAdListener`<br>`onAdExpanded(CloudXAd)`<br>`onAdCollapsed(CloudXAd)` | Banner/Native callbacks |
| `CloudXInterstitialListener` | Extends `CloudXAdListener` | Interstitial callbacks |
| `CloudXRewardedInterstitialListener` | Extends `CloudXAdListener`<br>`onUserRewarded(CloudXAd)` | Rewarded callbacks |
| `CloudXAdRevenueListener` | `onAdRevenuePaid(CloudXAd)` | Revenue tracking |

## Best Practices & Common Issues

- **Initialize once:** Call `CloudX.initialize()` in `Application.onCreate()` or first Activity
- **Privacy first:** Call `setPrivacy()` BEFORE `initialize()` to comply with GDPR/CCPA
- **IAB TCF/GPP:** If using a CMP, ensure it writes IAB strings to SharedPreferences before CloudX init
- **Always destroy:** Call `destroy()` in `onDestroy()` to prevent memory leaks
- **Check isAdReady:** For interstitials/rewarded, always check `isAdReady` before `show()`
- **Reload interstitials:** After showing, call `load()` again for next display
- **Auto-refresh:** Banners auto-refresh by default; use `startAutoRefresh()`/`stopAutoRefresh()` to control
- **Test mode:** Use `testMode = true` during development, `false` in production
- **Fallback integration:** Always implement fallback to AdMob/AppLovin/IronSource in `onAdLoadFailed()` - research fallback SDK docs using WebSearch when implementing
- **Handle all callbacks:** Implement all listener methods to avoid crashes (Kotlin: use empty implementations)
- **Thread safety:** All API calls are thread-safe; callbacks fire on main thread
- **Proguard:** No special rules needed; SDK handles obfuscation
- **Error handling:** Check `CloudXError.effectiveMessage` for debugging, use `CloudXErrorCode` for error categorization
