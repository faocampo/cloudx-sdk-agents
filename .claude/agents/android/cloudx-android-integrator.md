---
name: cloudx-android-integrator
description: Implements CloudX Android SDK with AdMob/AppLovin/IronSource fallback in Kotlin/Java
tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
model: sonnet
---

# CloudX Android Integration Agent

**SDK Version:** 0.8.0
**Last Updated:** 2025-11-24

## Mission

Implement CloudX SDK as the primary ad monetization solution with fallback to AdMob, AppLovin, or IronSource when CloudX ad loading fails. Research fallback SDK implementation details using WebSearch/WebFetch when needed to ensure proper integration patterns.

## Core Responsibilities

1. Add CloudX SDK dependencies to the project
2. Initialize CloudX SDK in Application.onCreate()
3. Configure privacy settings (GDPR/CCPA/COPPA/IAB TCF/GPP)
4. Implement all ad formats with CloudX as primary
5. Add fallback logic to AdMob/AppLovin/IronSource in onAdLoadFailed callbacks
6. Ensure proper lifecycle management
7. Research and implement best practices for fallback SDKs

## Integration Steps

### Step 1: Add Dependencies

Add CloudX SDK to your `build.gradle` (app module):

```gradle
dependencies {
    // CloudX SDK
    implementation 'io.cloudx:cloudx-android:0.8.0'

    // Existing fallback SDKs (keep these)
    // implementation 'com.google.android.gms:play-services-ads:...'
    // implementation 'com.applovin:applovin-sdk:...'
    // implementation 'com.ironsource.sdk:mediationsdk:...'
}
```

Add Maven repository if needed:

```gradle
repositories {
    maven { url 'https://sdk.cloudx.io/android/releases' }
}
```

### Step 2: Initialize SDK

Initialize CloudX SDK in your Application class before any ad operations:

```kotlin
import android.app.Application
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXInitializationParams
import io.cloudx.sdk.CloudXInitializationListener
import io.cloudx.sdk.CloudXError

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Configure privacy BEFORE initialization (required for GDPR/CCPA)
        CloudX.setPrivacy(getPrivacySettings())

        // Initialize CloudX SDK
        val params = CloudXInitializationParams(
            appKey = "YOUR_CLOUDX_APP_KEY",
            testMode = BuildConfig.DEBUG // Enable test ads in debug builds
        )

        CloudX.initialize(params, object : CloudXInitializationListener {
            override fun onInitialized() {
                Log.d("CloudX", "SDK initialized successfully")
                // Optionally initialize fallback SDKs here
                initializeFallbackSdks()
            }

            override fun onInitializationFailed(cloudXError: CloudXError) {
                Log.e("CloudX", "SDK initialization failed: ${cloudXError.effectiveMessage}")
                // Initialize fallback SDKs as backup
                initializeFallbackSdks()
            }
        })
    }

    private fun getPrivacySettings(): CloudXPrivacy {
        // Implement your privacy consent logic
        // This should check user's GDPR/CCPA consent status
        return CloudXPrivacy(
            isUserConsent = true, // Set based on user's consent
            isAgeRestrictedUser = false // Set based on COPPA requirements
        )
    }

    private fun initializeFallbackSdks() {
        // Initialize AdMob, AppLovin, or IronSource here
        // Example: MobileAds.initialize(this)
    }
}
```

**Java Example:**

```java
import android.app.Application;
import io.cloudx.sdk.CloudX;
import io.cloudx.sdk.CloudXInitializationParams;
import io.cloudx.sdk.CloudXInitializationListener;
import io.cloudx.sdk.CloudXPrivacy;
import io.cloudx.sdk.CloudXError;

public class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

        // Configure privacy BEFORE initialization
        CloudX.setPrivacy(getPrivacySettings());

        // Initialize CloudX SDK
        CloudXInitializationParams params = new CloudXInitializationParams(
            "YOUR_CLOUDX_APP_KEY",
            BuildConfig.DEBUG
        );

        CloudX.initialize(params, new CloudXInitializationListener() {
            @Override
            public void onInitialized() {
                Log.d("CloudX", "SDK initialized successfully");
                initializeFallbackSdks();
            }

            @Override
            public void onInitializationFailed(CloudXError cloudXError) {
                Log.e("CloudX", "SDK initialization failed: " + cloudXError.getEffectiveMessage());
                initializeFallbackSdks();
            }
        });
    }

    private CloudXPrivacy getPrivacySettings() {
        return new CloudXPrivacy(true, false);
    }

    private void initializeFallbackSdks() {
        // Initialize AdMob, AppLovin, or IronSource
    }
}
```

### Step 3: Privacy Configuration

CloudX SDK supports GDPR, CCPA, and COPPA compliance. Additionally, it can read IAB TCF/GPP strings if your app uses a CMP (Consent Management Platform).

**GDPR Compliance:**

```kotlin
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXPrivacy

// Before showing ads, get user consent
fun updateGdprConsent(hasConsent: Boolean) {
    CloudX.setPrivacy(CloudXPrivacy(
        isUserConsent = hasConsent,
        isAgeRestrictedUser = null
    ))
}
```

**CCPA Compliance:**

```kotlin
// For California users
fun updateCcpaConsent(hasConsent: Boolean) {
    CloudX.setPrivacy(CloudXPrivacy(
        isUserConsent = hasConsent,
        isAgeRestrictedUser = null
    ))
}
```

**COPPA Compliance:**

```kotlin
// For age-restricted users
fun updateCoppaStatus(isChild: Boolean) {
    CloudX.setPrivacy(CloudXPrivacy(
        isUserConsent = null,
        isAgeRestrictedUser = isChild
    ))
}
```

**IAB TCF/GPP Support:**

CloudX SDK automatically reads IAB Transparency & Consent Framework (TCF) and Global Privacy Platform (GPP) strings from SharedPreferences if your app uses a CMP. No additional configuration needed - just ensure your CMP writes standard IAB strings to SharedPreferences.

**Important Privacy Rules:**

1. Call `CloudX.setPrivacy()` BEFORE `CloudX.initialize()`
2. Update privacy settings whenever user consent changes
3. Forward privacy signals to fallback SDKs (AdMob, AppLovin, IronSource)

### Step 4: Implement Ad Formats

#### Banner Ads (320x50)

**Kotlin Example:**

```kotlin
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXAdView
import io.cloudx.sdk.CloudXAdViewListener
import io.cloudx.sdk.CloudXAd
import io.cloudx.sdk.CloudXError

class MainActivity : AppCompatActivity() {
    private lateinit var bannerView: CloudXAdView
    private var fallbackBanner: AdView? = null // AdMob example

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Create CloudX banner
        bannerView = CloudX.createBanner("banner_placement")
        bannerView.listener = object : CloudXAdViewListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                Log.d("Banner", "CloudX banner loaded from ${cloudXAd.bidderName}")
            }

            override fun onAdLoadFailed(cloudXError: CloudXError) {
                Log.e("Banner", "CloudX banner failed: ${cloudXError.effectiveMessage}")
                // Fallback to AdMob
                loadAdMobBanner()
            }

            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                Log.d("Banner", "CloudX banner displayed")
            }

            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                Log.e("Banner", "CloudX banner display failed: ${cloudXError.effectiveMessage}")
            }

            override fun onAdHidden(cloudXAd: CloudXAd) {
                Log.d("Banner", "CloudX banner hidden")
            }

            override fun onAdClicked(cloudXAd: CloudXAd) {
                Log.d("Banner", "CloudX banner clicked")
            }

            override fun onAdExpanded(cloudXAd: CloudXAd) {
                Log.d("Banner", "CloudX banner expanded")
            }

            override fun onAdCollapsed(cloudXAd: CloudXAd) {
                Log.d("Banner", "CloudX banner collapsed")
            }
        }

        // Add to layout
        val container = findViewById<FrameLayout>(R.id.banner_container)
        container.addView(bannerView)

        // Load ad
        bannerView.load()

        // Optional: Enable auto-refresh
        bannerView.startAutoRefresh()
    }

    private fun loadAdMobBanner() {
        // Fallback to AdMob
        fallbackBanner = AdView(this).apply {
            adUnitId = "ca-app-pub-XXXX/XXXX"
            setAdSize(AdSize.BANNER)
            loadAd(AdRequest.Builder().build())
        }
        findViewById<FrameLayout>(R.id.banner_container).addView(fallbackBanner)
    }

    override fun onDestroy() {
        super.onDestroy()
        bannerView.destroy()
        fallbackBanner?.destroy()
    }
}
```

**Java Example:**

```java
import io.cloudx.sdk.CloudX;
import io.cloudx.sdk.CloudXAdView;
import io.cloudx.sdk.CloudXAdViewListener;
import io.cloudx.sdk.CloudXAd;
import io.cloudx.sdk.CloudXError;

public class MainActivity extends AppCompatActivity {
    private CloudXAdView bannerView;
    private AdView fallbackBanner;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Create CloudX banner
        bannerView = CloudX.createBanner("banner_placement");
        bannerView.setListener(new CloudXAdViewListener() {
            @Override
            public void onAdLoaded(CloudXAd cloudXAd) {
                Log.d("Banner", "CloudX banner loaded");
            }

            @Override
            public void onAdLoadFailed(CloudXError cloudXError) {
                Log.e("Banner", "CloudX banner failed: " + cloudXError.getEffectiveMessage());
                loadAdMobBanner();
            }

            @Override
            public void onAdDisplayed(CloudXAd cloudXAd) {
                Log.d("Banner", "CloudX banner displayed");
            }

            @Override
            public void onAdDisplayFailed(CloudXError cloudXError) {
                Log.e("Banner", "Display failed");
            }

            @Override
            public void onAdHidden(CloudXAd cloudXAd) {}

            @Override
            public void onAdClicked(CloudXAd cloudXAd) {}

            @Override
            public void onAdExpanded(CloudXAd cloudXAd) {}

            @Override
            public void onAdCollapsed(CloudXAd cloudXAd) {}
        });

        FrameLayout container = findViewById(R.id.banner_container);
        container.addView(bannerView);
        bannerView.load();
        bannerView.startAutoRefresh();
    }

    private void loadAdMobBanner() {
        fallbackBanner = new AdView(this);
        fallbackBanner.setAdUnitId("ca-app-pub-XXXX/XXXX");
        fallbackBanner.setAdSize(AdSize.BANNER);
        fallbackBanner.loadAd(new AdRequest.Builder().build());
        ((FrameLayout) findViewById(R.id.banner_container)).addView(fallbackBanner);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        bannerView.destroy();
        if (fallbackBanner != null) {
            fallbackBanner.destroy();
        }
    }
}
```

#### MREC Ads (300x250)

```kotlin
import io.cloudx.sdk.CloudX

// Create MREC banner
val mrecView = CloudX.createMREC("mrec_placement")
mrecView.listener = object : CloudXAdViewListener {
    override fun onAdLoaded(cloudXAd: CloudXAd) {
        Log.d("MREC", "CloudX MREC loaded")
    }

    override fun onAdLoadFailed(cloudXError: CloudXError) {
        Log.e("MREC", "CloudX MREC failed: ${cloudXError.effectiveMessage}")
        // Fallback to AdMob MREC
        loadAdMobMrec()
    }

    override fun onAdDisplayed(cloudXAd: CloudXAd) {}
    override fun onAdDisplayFailed(cloudXError: CloudXError) {}
    override fun onAdHidden(cloudXAd: CloudXAd) {}
    override fun onAdClicked(cloudXAd: CloudXAd) {}
    override fun onAdExpanded(cloudXAd: CloudXAd) {}
    override fun onAdCollapsed(cloudXAd: CloudXAd) {}
}

// Add to layout and load
container.addView(mrecView)
mrecView.load()
mrecView.startAutoRefresh()
```

#### Interstitial Ads

**Kotlin Example:**

```kotlin
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXInterstitialAd
import io.cloudx.sdk.CloudXInterstitialListener

class MainActivity : AppCompatActivity() {
    private lateinit var interstitialAd: CloudXInterstitialAd
    private var fallbackInterstitial: InterstitialAd? = null // AdMob example

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        loadInterstitial()
    }

    private fun loadInterstitial() {
        // Create CloudX interstitial
        interstitialAd = CloudX.createInterstitial("interstitial_placement")
        interstitialAd.listener = object : CloudXInterstitialListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                Log.d("Interstitial", "CloudX interstitial loaded from ${cloudXAd.bidderName}")
                // Ad is ready to show
            }

            override fun onAdLoadFailed(cloudXError: CloudXError) {
                Log.e("Interstitial", "CloudX interstitial failed: ${cloudXError.effectiveMessage}")
                // Fallback to AdMob
                loadAdMobInterstitial()
            }

            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                Log.d("Interstitial", "CloudX interstitial displayed")
            }

            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                Log.e("Interstitial", "CloudX interstitial display failed")
            }

            override fun onAdHidden(cloudXAd: CloudXAd) {
                Log.d("Interstitial", "CloudX interstitial hidden")
                // Load next ad
                loadInterstitial()
            }

            override fun onAdClicked(cloudXAd: CloudXAd) {
                Log.d("Interstitial", "CloudX interstitial clicked")
            }
        }

        // Load ad
        interstitialAd.load()
    }

    private fun loadAdMobInterstitial() {
        // Fallback to AdMob
        InterstitialAd.load(
            this,
            "ca-app-pub-XXXX/XXXX",
            AdRequest.Builder().build(),
            object : InterstitialAdLoadCallback() {
                override fun onAdLoaded(ad: InterstitialAd) {
                    fallbackInterstitial = ad
                }
            }
        )
    }

    private fun showInterstitial() {
        when {
            interstitialAd.isAdReady -> interstitialAd.show()
            fallbackInterstitial != null -> fallbackInterstitial?.show(this)
            else -> Log.d("Interstitial", "No ad ready to show")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        interstitialAd.destroy()
    }
}
```

**Java Example:**

```java
import io.cloudx.sdk.CloudX;
import io.cloudx.sdk.CloudXInterstitialAd;
import io.cloudx.sdk.CloudXInterstitialListener;

public class MainActivity extends AppCompatActivity {
    private CloudXInterstitialAd interstitialAd;
    private InterstitialAd fallbackInterstitial;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        loadInterstitial();
    }

    private void loadInterstitial() {
        interstitialAd = CloudX.createInterstitial("interstitial_placement");
        interstitialAd.setListener(new CloudXInterstitialListener() {
            @Override
            public void onAdLoaded(CloudXAd cloudXAd) {
                Log.d("Interstitial", "CloudX interstitial loaded");
            }

            @Override
            public void onAdLoadFailed(CloudXError cloudXError) {
                Log.e("Interstitial", "CloudX failed: " + cloudXError.getEffectiveMessage());
                loadAdMobInterstitial();
            }

            @Override
            public void onAdDisplayed(CloudXAd cloudXAd) {
                Log.d("Interstitial", "CloudX interstitial displayed");
            }

            @Override
            public void onAdDisplayFailed(CloudXError cloudXError) {
                Log.e("Interstitial", "Display failed");
            }

            @Override
            public void onAdHidden(CloudXAd cloudXAd) {
                loadInterstitial();
            }

            @Override
            public void onAdClicked(CloudXAd cloudXAd) {}
        });

        interstitialAd.load();
    }

    private void loadAdMobInterstitial() {
        InterstitialAd.load(
            this,
            "ca-app-pub-XXXX/XXXX",
            new AdRequest.Builder().build(),
            new InterstitialAdLoadCallback() {
                @Override
                public void onAdLoaded(InterstitialAd ad) {
                    fallbackInterstitial = ad;
                }
            }
        );
    }

    private void showInterstitial() {
        if (interstitialAd.isAdReady()) {
            interstitialAd.show();
        } else if (fallbackInterstitial != null) {
            fallbackInterstitial.show(this);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        interstitialAd.destroy();
    }
}
```

#### Rewarded Interstitial Ads

**Kotlin Example:**

```kotlin
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXRewardedInterstitialAd
import io.cloudx.sdk.CloudXRewardedInterstitialListener

class MainActivity : AppCompatActivity() {
    private lateinit var rewardedAd: CloudXRewardedInterstitialAd
    private var fallbackRewarded: RewardedAd? = null // AdMob example

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        loadRewardedAd()
    }

    private fun loadRewardedAd() {
        // Create CloudX rewarded interstitial
        rewardedAd = CloudX.createRewardedInterstitial("rewarded_placement")
        rewardedAd.listener = object : CloudXRewardedInterstitialListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                Log.d("Rewarded", "CloudX rewarded loaded from ${cloudXAd.bidderName}")
            }

            override fun onAdLoadFailed(cloudXError: CloudXError) {
                Log.e("Rewarded", "CloudX rewarded failed: ${cloudXError.effectiveMessage}")
                // Fallback to AdMob
                loadAdMobRewarded()
            }

            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                Log.d("Rewarded", "CloudX rewarded displayed")
            }

            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                Log.e("Rewarded", "CloudX rewarded display failed")
            }

            override fun onAdHidden(cloudXAd: CloudXAd) {
                Log.d("Rewarded", "CloudX rewarded hidden")
                // Load next ad
                loadRewardedAd()
            }

            override fun onAdClicked(cloudXAd: CloudXAd) {
                Log.d("Rewarded", "CloudX rewarded clicked")
            }

            override fun onUserRewarded(cloudXAd: CloudXAd) {
                Log.d("Rewarded", "User rewarded!")
                // Grant reward to user
                grantReward()
            }
        }

        // Optional: Track revenue
        rewardedAd.revenueListener = object : CloudXAdRevenueListener {
            override fun onAdRevenuePaid(cloudXAd: CloudXAd) {
                Log.d("Rewarded", "Revenue: ${cloudXAd.revenue}")
                // Track revenue in analytics
            }
        }

        // Load ad
        rewardedAd.load()
    }

    private fun loadAdMobRewarded() {
        // Fallback to AdMob
        RewardedAd.load(
            this,
            "ca-app-pub-XXXX/XXXX",
            AdRequest.Builder().build(),
            object : RewardedAdLoadCallback() {
                override fun onAdLoaded(ad: RewardedAd) {
                    fallbackRewarded = ad
                }
            }
        )
    }

    private fun showRewardedAd() {
        when {
            rewardedAd.isAdReady -> rewardedAd.show()
            fallbackRewarded != null -> fallbackRewarded?.show(this) { grantReward() }
            else -> Log.d("Rewarded", "No ad ready to show")
        }
    }

    private fun grantReward() {
        // Implement your reward logic
        Log.d("Rewarded", "Granting reward to user")
    }

    override fun onDestroy() {
        super.onDestroy()
        rewardedAd.destroy()
    }
}
```

#### Native Ads

CloudX SDK supports native ads in two sizes:

**Small Native Ads:**

```kotlin
import io.cloudx.sdk.CloudX

// Create small native ad
val nativeAdSmall = CloudX.createNativeAdSmall("native_small_placement")
nativeAdSmall.listener = object : CloudXAdViewListener {
    override fun onAdLoaded(cloudXAd: CloudXAd) {
        Log.d("NativeSmall", "CloudX native small loaded")
    }

    override fun onAdLoadFailed(cloudXError: CloudXError) {
        Log.e("NativeSmall", "CloudX native small failed: ${cloudXError.effectiveMessage}")
        // Fallback to AdMob native ad
        loadAdMobNativeAd()
    }

    override fun onAdDisplayed(cloudXAd: CloudXAd) {}
    override fun onAdDisplayFailed(cloudXError: CloudXError) {}
    override fun onAdHidden(cloudXAd: CloudXAd) {}
    override fun onAdClicked(cloudXAd: CloudXAd) {}
    override fun onAdExpanded(cloudXAd: CloudXAd) {}
    override fun onAdCollapsed(cloudXAd: CloudXAd) {}
}

// Add to layout and load
container.addView(nativeAdSmall)
nativeAdSmall.load()
```

**Medium Native Ads:**

```kotlin
// Create medium native ad
val nativeAdMedium = CloudX.createNativeAdMedium("native_medium_placement")
nativeAdMedium.listener = object : CloudXAdViewListener {
    override fun onAdLoaded(cloudXAd: CloudXAd) {
        Log.d("NativeMedium", "CloudX native medium loaded")
    }

    override fun onAdLoadFailed(cloudXError: CloudXError) {
        Log.e("NativeMedium", "CloudX native medium failed: ${cloudXError.effectiveMessage}")
        // Fallback to AdMob native ad
        loadAdMobNativeAd()
    }

    override fun onAdDisplayed(cloudXAd: CloudXAd) {}
    override fun onAdDisplayFailed(cloudXError: CloudXError) {}
    override fun onAdHidden(cloudXAd: CloudXAd) {}
    override fun onAdClicked(cloudXAd: CloudXAd) {}
    override fun onAdExpanded(cloudXAd: CloudXAd) {}
    override fun onAdCollapsed(cloudXAd: CloudXAd) {}
}

// Add to layout and load
container.addView(nativeAdMedium)
nativeAdMedium.load()
```

### Step 5: Advanced Features

#### Logging Configuration

```kotlin
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXLogLevel

// Enable logging for debugging
CloudX.setLoggingEnabled(true)

// Set minimum log level
CloudX.setMinLogLevel(CloudXLogLevel.DEBUG)

// Available log levels:
// - VERBOSE
// - DEBUG
// - INFO
// - WARN
// - ERROR
```

#### User Identification

```kotlin
import io.cloudx.sdk.CloudX

// Set hashed user ID (for targeting)
// Publisher is responsible for normalization and hashing
CloudX.setHashedUserId("hashed_user_id_123")
```

#### Key-Value Targeting

```kotlin
import io.cloudx.sdk.CloudX

// Set user-level key-values
CloudX.setUserKeyValue("vip_status", "gold")
CloudX.setUserKeyValue("lifetime_value", "high")

// Set app-level key-values
CloudX.setAppKeyValue("content_category", "sports")
CloudX.setAppKeyValue("app_version", "2.1.0")

// Clear all key-values
CloudX.clearAllKeyValues()
```

#### Revenue Tracking

```kotlin
import io.cloudx.sdk.CloudXAdRevenueListener

// Track ad revenue for any ad format
rewardedAd.revenueListener = object : CloudXAdRevenueListener {
    override fun onAdRevenuePaid(cloudXAd: CloudXAd) {
        val revenue = cloudXAd.revenue
        val bidderName = cloudXAd.bidderName
        val placementName = cloudXAd.placementName

        Log.d("Revenue", "Ad revenue: $revenue from $bidderName")

        // Send to analytics
        // Firebase.analytics.logEvent("ad_revenue") { ... }
        // Or Adjust.trackAdRevenue(...)
    }
}
```

## Complete API Reference

### CloudX (Main Entry Point)

```kotlin
object CloudX {
    // Initialization
    fun initialize(
        initParams: CloudXInitializationParams,
        listener: CloudXInitializationListener?
    )

    fun deinitialize()

    // Ad Creation
    fun createBanner(placementName: String): CloudXAdView
    fun createMREC(placementName: String): CloudXAdView
    fun createInterstitial(placementName: String): CloudXInterstitialAd
    fun createRewardedInterstitial(placementName: String): CloudXRewardedInterstitialAd
    fun createNativeAdSmall(placementName: String): CloudXAdView
    fun createNativeAdMedium(placementName: String): CloudXAdView

    // Privacy
    fun setPrivacy(privacy: CloudXPrivacy)

    // Logging
    fun setLoggingEnabled(isEnabled: Boolean)
    fun setMinLogLevel(minLogLevel: CloudXLogLevel)

    // Targeting
    fun setHashedUserId(hashedUserId: String)
    fun setUserKeyValue(key: String, value: String)
    fun setAppKeyValue(key: String, value: String)
    fun clearAllKeyValues()
}
```

### CloudXInitializationParams

```kotlin
data class CloudXInitializationParams(
    val appKey: String,
    val testMode: Boolean = false
)
```

### CloudXPrivacy

```kotlin
data class CloudXPrivacy(
    val isUserConsent: Boolean? = null,        // GDPR consent
    val isAgeRestrictedUser: Boolean? = null   // COPPA flag
)
```

### CloudXAdView

```kotlin
class CloudXAdView : FrameLayout, CloudXDestroyable {
    var listener: CloudXAdViewListener?

    fun load()
    fun startAutoRefresh()
    fun stopAutoRefresh()
    fun destroy()
}
```

### CloudXInterstitialAd

```kotlin
interface CloudXInterstitialAd : CloudXFullscreenAd<CloudXInterstitialListener>
```

### CloudXRewardedInterstitialAd

```kotlin
interface CloudXRewardedInterstitialAd : CloudXFullscreenAd<CloudXRewardedInterstitialListener>
```

### CloudXFullscreenAd

```kotlin
interface CloudXFullscreenAd<T: CloudXAdListener> : CloudXDestroyable {
    var listener: T?
    var revenueListener: CloudXAdRevenueListener?
    val isAdReady: Boolean

    fun load()
    fun show()
    fun destroy()
}
```

### CloudXAdListener

```kotlin
interface CloudXAdListener {
    fun onAdLoaded(cloudXAd: CloudXAd)
    fun onAdLoadFailed(cloudXError: CloudXError)
    fun onAdDisplayed(cloudXAd: CloudXAd)
    fun onAdDisplayFailed(cloudXError: CloudXError)
    fun onAdHidden(cloudXAd: CloudXAd)
    fun onAdClicked(cloudXAd: CloudXAd)
}
```

### CloudXAdViewListener

```kotlin
interface CloudXAdViewListener : CloudXAdListener {
    fun onAdExpanded(cloudXAd: CloudXAd)
    fun onAdCollapsed(cloudXAd: CloudXAd)
}
```

### CloudXInterstitialListener

```kotlin
interface CloudXInterstitialListener : CloudXAdListener
```

### CloudXRewardedInterstitialListener

```kotlin
interface CloudXRewardedInterstitialListener : CloudXAdListener {
    fun onUserRewarded(cloudXAd: CloudXAd)
}
```

### CloudXAdRevenueListener

```kotlin
interface CloudXAdRevenueListener {
    fun onAdRevenuePaid(cloudXAd: CloudXAd)
}
```

### CloudXInitializationListener

```kotlin
interface CloudXInitializationListener {
    fun onInitialized()
    fun onInitializationFailed(cloudXError: CloudXError)
}
```

### CloudXAd

```kotlin
interface CloudXAd {
    val placementName: String
    val placementId: String
    val bidderName: String
    val externalPlacementId: String?
    val revenue: Double
}
```

### CloudXError

```kotlin
data class CloudXError(
    val code: CloudXErrorCode,
    val message: String? = null,
    val cause: Throwable? = null
) {
    val effectiveMessage: String
}
```

### CloudXErrorCode

```kotlin
enum class CloudXErrorCode {
    // Initialization (100-199)
    NOT_INITIALIZED,
    INITIALIZATION_IN_PROGRESS,
    NO_ADAPTERS_FOUND,
    INITIALIZATION_TIMEOUT,
    INVALID_APP_KEY,
    SDK_DISABLED,

    // Network (200-299)
    NETWORK_ERROR,
    NETWORK_TIMEOUT,
    INVALID_RESPONSE,
    SERVER_ERROR,
    CLIENT_ERROR,

    // Ad Loading (300-399)
    NO_FILL,
    INVALID_REQUEST,
    INVALID_PLACEMENT,
    LOAD_TIMEOUT,
    LOAD_FAILED,
    INVALID_AD,
    TOO_MANY_REQUESTS,
    REQUEST_CANCELLED,
    ADS_DISABLED,

    // Ad Display (400-499)
    AD_NOT_READY,
    AD_ALREADY_DISPLAYED,
    AD_EXPIRED,
    INVALID_VIEW_CONTROLLER,
    DISPLAY_FAILED,

    // Configuration (500-599)
    INVALID_AD_UNIT,
    PERMISSION_DENIED,
    UNSUPPORTED_AD_FORMAT,
    INVALID_BANNER_VIEW,
    INVALID_NATIVE_VIEW,

    // Adapter (600-699)
    ADAPTER_UNEXPECTED_ERROR,
    ADAPTER_INITIALIZATION_ERROR,
    ADAPTER_INVALID_SERVER_EXTRAS,
    ADAPTER_NO_CONNECTION,
    ADAPTER_NO_FILL,
    ADAPTER_SERVER_ERROR,
    ADAPTER_TIMEOUT,
    ADAPTER_INVALID_LOAD_STATE,
    ADAPTER_INVALID_CONFIGURATION,

    // General (700-799)
    UNEXPECTED_ERROR
}
```

### CloudXLogLevel

```kotlin
enum class CloudXLogLevel {
    VERBOSE,
    DEBUG,
    INFO,
    WARN,
    ERROR
}
```

### CloudXDestroyable

```kotlin
interface CloudXDestroyable {
    fun destroy()
}
```

## Best Practices

### 1. CloudX as Primary, Fallback as Secondary

Always try CloudX first, only use fallback SDKs (AdMob/AppLovin/IronSource) in `onAdLoadFailed`:

```kotlin
override fun onAdLoadFailed(cloudXError: CloudXError) {
    // Only now load AdMob/AppLovin/IronSource
    loadFallbackAd()
}
```

### 2. Initialize SDK Early

Initialize CloudX SDK in `Application.onCreate()`, not in Activity:

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CloudX.setPrivacy(getPrivacySettings())
        CloudX.initialize(params, listener)
    }
}
```

### 3. Set Privacy Before Initialization

Always call `CloudX.setPrivacy()` BEFORE `CloudX.initialize()`:

```kotlin
// Correct order
CloudX.setPrivacy(privacy)
CloudX.initialize(params, listener)

// Wrong order - privacy settings may not apply
CloudX.initialize(params, listener)
CloudX.setPrivacy(privacy)
```

### 4. Always Call destroy()

Call `destroy()` in `onDestroy()` to prevent memory leaks:

```kotlin
override fun onDestroy() {
    super.onDestroy()
    bannerView.destroy()
    interstitialAd.destroy()
    rewardedAd.destroy()
}
```

### 5. Handle All Listener Callbacks

Implement all required listener methods to handle ad lifecycle properly:

```kotlin
override fun onAdLoaded(cloudXAd: CloudXAd) { /* Handle success */ }
override fun onAdLoadFailed(cloudXError: CloudXError) { /* Handle failure */ }
override fun onAdDisplayed(cloudXAd: CloudXAd) { /* Handle display */ }
override fun onAdDisplayFailed(cloudXError: CloudXError) { /* Handle display failure */ }
override fun onAdHidden(cloudXAd: CloudXAd) { /* Load next ad */ }
override fun onAdClicked(cloudXAd: CloudXAd) { /* Track click */ }
```

### 6. Test Fallback Paths

Test that fallback to AdMob/AppLovin/IronSource works correctly:

1. Disable internet to force CloudX to fail
2. Verify fallback SDK loads
3. Re-enable internet and verify CloudX loads again

### 7. Forward Privacy Signals to Fallback SDKs

When setting privacy for CloudX, also forward the same privacy signals to your fallback SDKs:

```kotlin
fun updatePrivacy(hasConsent: Boolean) {
    // Update CloudX
    CloudX.setPrivacy(CloudXPrivacy(isUserConsent = hasConsent))

    // Update AdMob
    val consentInformation = UserMessagingPlatform.getConsentInformation(context)
    // Configure AdMob consent...

    // Update AppLovin
    AppLovinPrivacySettings.setHasUserConsent(hasConsent, context)

    // Update IronSource
    IronSource.setConsent(hasConsent)
}
```

### 8. Enable Test Ads During Development

Use test mode during development to avoid policy violations:

```kotlin
CloudXInitializationParams(
    appKey = "your_app_key",
    testMode = BuildConfig.DEBUG // Test ads in debug builds
)
```

### 9. Track Revenue in Analytics

Forward CloudX revenue to your analytics platform:

```kotlin
revenueListener = object : CloudXAdRevenueListener {
    override fun onAdRevenuePaid(cloudXAd: CloudXAd) {
        // Firebase Analytics
        firebaseAnalytics.logEvent("ad_impression") {
            param("ad_platform", "CloudX")
            param("ad_source", cloudXAd.bidderName)
            param("ad_format", "rewarded")
            param("value", cloudXAd.revenue)
            param("currency", "USD")
        }

        // Adjust
        val adRevenue = AdjustAdRevenue(AdjustConfig.AD_REVENUE_SOURCE_PUBLISHER)
        adRevenue.setRevenue(cloudXAd.revenue, "USD")
        Adjust.trackAdRevenue(adRevenue)
    }
}
```

### 10. Use Auto-Refresh for Banner Ads

Enable auto-refresh for banner and MREC ads:

```kotlin
bannerView.startAutoRefresh()

// Stop auto-refresh when not needed (e.g., user scrolls past)
bannerView.stopAutoRefresh()
```

## Common Issues and Solutions

### Issue 1: SDK Not Initialized

**Error:** `CloudXErrorCode.NOT_INITIALIZED`

**Solution:** Initialize SDK in `Application.onCreate()` before any ad operations:

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CloudX.initialize(params, listener)
    }
}
```

Don't forget to register in `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApplication"
    ...>
```

### Issue 2: Missing Permissions

**Error:** Network errors or initialization failures

**Solution:** Add required permissions to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Issue 3: Privacy Not Applied

**Problem:** Privacy settings don't take effect

**Solution:** Call `CloudX.setPrivacy()` BEFORE `CloudX.initialize()`:

```kotlin
// Correct
CloudX.setPrivacy(privacy)
CloudX.initialize(params, listener)
```

### Issue 4: Memory Leaks

**Problem:** Activity leaks or OutOfMemoryError

**Solution:** Always call `destroy()` in `onDestroy()`:

```kotlin
override fun onDestroy() {
    super.onDestroy()
    bannerView.destroy()
    interstitialAd.destroy()
    rewardedAd.destroy()
}
```

### Issue 5: Fallback Not Working

**Problem:** When CloudX fails, no ads are shown

**Solution:** Implement fallback in `onAdLoadFailed`:

```kotlin
override fun onAdLoadFailed(cloudXError: CloudXError) {
    Log.e("Ad", "CloudX failed: ${cloudXError.effectiveMessage}")
    loadAdMobAd() // Load fallback
}
```

### Issue 6: Ads Not Showing in Production

**Problem:** Test ads work, but production ads don't show

**Solution:** Set `testMode = false` in production:

```kotlin
CloudXInitializationParams(
    appKey = "your_app_key",
    testMode = false // Production ads
)
```

### Issue 7: Invalid Placement

**Error:** `CloudXErrorCode.INVALID_PLACEMENT`

**Solution:** Verify placement name matches CloudX dashboard:

```kotlin
// Make sure this matches your CloudX dashboard configuration
val banner = CloudX.createBanner("banner_placement")
```

## AndroidManifest.xml Configuration

Add required elements to your `AndroidManifest.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Required Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Optional Permissions (for better targeting) -->
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />

    <application
        android:name=".MyApplication"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config"
        ...>

        <!-- Your activities -->
        <activity android:name=".MainActivity">
            ...
        </activity>

    </application>
</manifest>
```

## ProGuard/R8 Configuration

CloudX SDK is already optimized for ProGuard/R8. No additional rules needed.

If you encounter issues, add these rules to `proguard-rules.pro`:

```proguard
# CloudX SDK
-keep class io.cloudx.sdk.** { *; }
-keepclassmembers class io.cloudx.sdk.** { *; }
```

## Testing Checklist

Before releasing your app with CloudX SDK:

- [ ] SDK initializes successfully in Application.onCreate()
- [ ] Privacy settings are applied before initialization
- [ ] All ad formats load correctly (banner, MREC, interstitial, rewarded, native)
- [ ] Fallback to AdMob/AppLovin/IronSource works when CloudX fails
- [ ] destroy() is called for all ad instances in onDestroy()
- [ ] Test ads work in debug builds (testMode = true)
- [ ] Production ads work in release builds (testMode = false)
- [ ] Privacy policy is updated to mention CloudX SDK
- [ ] GDPR/CCPA consent flows work correctly
- [ ] Revenue tracking is integrated with analytics
- [ ] No memory leaks (use LeakCanary)
- [ ] ProGuard/R8 builds work correctly

## Support and Resources

- **Documentation:** https://docs.cloudx.io/android
- **GitHub:** https://github.com/cloudx-io/cloudexchange.android.sdk
- **Support:** support@cloudx.io
- **Dashboard:** https://dashboard.cloudx.io

## Migration from Other SDKs

If you're migrating from AdMob/AppLovin/IronSource to CloudX:

1. Keep your existing SDK integration
2. Add CloudX SDK as primary
3. Use existing SDK as fallback
4. Gradually increase CloudX traffic
5. Monitor revenue and performance
6. Adjust CloudX/fallback ratio as needed

This ensures zero downtime and no revenue loss during migration.
