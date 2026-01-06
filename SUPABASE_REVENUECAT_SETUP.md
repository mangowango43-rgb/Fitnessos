# 🔥 COMPLETE SUPABASE + REVENUECAT SETUP GUIDE

## 📦 PART 1: SUPABASE SETUP

### Step 1: Create Supabase Project
1. Go to https://supabase.com
2. Click "Start your project"
3. Create new organization (e.g., "FitnessOS")
4. Create new project:
   - Name: `fitnessos-prod`
   - Database Password: **SAVE THIS SECURELY**
   - Region: Choose closest to your users
5. Wait for project to provision (~2 mins)

### Step 2: Get Your Supabase Credentials
1. In Supabase Dashboard → Settings → API
2. Copy these values:
   ```
   Project URL: https://xxxxxxxxxxxxx.supabase.co
   anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ey...
   ```

### Step 3: Set Up Authentication

#### Enable Auth Providers
1. Go to Authentication → Providers
2. Enable these providers:
   - **Email** (already enabled)
   - **Google OAuth**:
     - Get credentials from Google Cloud Console
     - Enable Google+ API
     - Create OAuth 2.0 credentials
     - Add authorized redirect URI: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
   - **Apple Sign In**:
     - Get credentials from Apple Developer Portal
     - Services ID, Team ID, Key ID
     - Upload your .p8 key file

#### Configure Email Templates
1. Go to Authentication → Email Templates
2. Customize:
   - Confirmation email
   - Magic link email
   - Reset password email
3. Use your branding (FitnessOS logo, colors)

### Step 4: Create Database Tables

Run these SQL commands in Supabase SQL Editor:

```sql
-- Users Profile Table
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Personal Info
  name TEXT,
  email TEXT,
  avatar_url TEXT,
  
  -- Fitness Data
  age INTEGER,
  weight DECIMAL(5,2),
  target_weight DECIMAL(5,2),
  goal_mode TEXT, -- 'cut', 'bulk', 'maintain', 'recomp'
  equipment_mode TEXT, -- 'bodyweight', 'dumbbells', 'gym'
  fitness_experience TEXT,
  injuries TEXT,
  dietary_restrictions TEXT,
  
  -- Preferences
  preferred_days TEXT[], -- Array of days
  coaching_style TEXT,
  motivations TEXT[],
  
  -- Stats
  total_workouts INTEGER DEFAULT 0,
  total_reps INTEGER DEFAULT 0,
  total_sets INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_workout_date DATE,
  
  -- Subscription (RevenueCat will sync here)
  is_premium BOOLEAN DEFAULT FALSE,
  subscription_status TEXT, -- 'active', 'cancelled', 'expired', 'trial'
  subscription_end_date TIMESTAMPTZ,
  revenue_cat_user_id TEXT
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can only read/update their own profile
CREATE POLICY "Users can view own profile" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

-- Automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Workouts Table
CREATE TABLE public.workouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  workout_name TEXT NOT NULL,
  exercises JSONB NOT NULL, -- Array of exercises
  total_duration_seconds INTEGER,
  total_reps INTEGER,
  total_sets INTEGER,
  completed BOOLEAN DEFAULT TRUE
);

ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own workouts" 
  ON public.workouts FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workouts" 
  ON public.workouts FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Workout Recordings Table
CREATE TABLE public.workout_recordings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  workout_name TEXT NOT NULL,
  video_url TEXT, -- Storage URL
  thumbnail_url TEXT,
  duration_seconds INTEGER,
  date DATE DEFAULT CURRENT_DATE
);

ALTER TABLE public.workout_recordings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own recordings" 
  ON public.workout_recordings FOR ALL 
  USING (auth.uid() = user_id);

-- Workout Schedules Table
CREATE TABLE public.workout_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  workout_id TEXT,
  workout_name TEXT NOT NULL,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  has_alarm BOOLEAN DEFAULT FALSE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ
);

ALTER TABLE public.workout_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own schedules" 
  ON public.workout_schedules FOR ALL 
  USING (auth.uid() = user_id);

-- Analytics/Events Table
CREATE TABLE public.analytics_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  event_name TEXT NOT NULL,
  event_properties JSONB,
  session_id TEXT,
  device_info JSONB
);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own events" 
  ON public.analytics_events FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX idx_workouts_created_at ON public.workouts(created_at DESC);
CREATE INDEX idx_recordings_user_id ON public.workout_recordings(user_id);
CREATE INDEX idx_schedules_user_id ON public.workout_schedules(user_id);
CREATE INDEX idx_schedules_date ON public.workout_schedules(scheduled_date);
CREATE INDEX idx_analytics_user_id ON public.analytics_events(user_id);
CREATE INDEX idx_analytics_event_name ON public.analytics_events(event_name);
```

### Step 5: Set Up Storage Buckets

1. Go to Storage → Create new bucket
2. Create bucket: `workout-videos`
   - Public: NO (users access their own only)
   - Allowed MIME types: `video/mp4, video/quicktime`
   - Max file size: 500MB
3. Create bucket: `avatars`
   - Public: YES (profile pics can be public)
   - Allowed MIME types: `image/*`
   - Max file size: 5MB

#### Storage Policies

```sql
-- Workout Videos: Users can only access their own
CREATE POLICY "Users can upload own videos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'workout-videos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own videos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'workout-videos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete own videos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'workout-videos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Avatars: Anyone can view, users can update own
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## 📦 PART 2: FLUTTER INTEGRATION

### Step 1: Add Dependencies to pubspec.yaml

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  flutter_secure_storage: ^9.0.0
```

### Step 2: Create Supabase Service

Create `lib/services/supabase_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
  
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get userId => currentUser?.id;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // More secure
      ),
    );
  }
  
  // AUTH METHODS
  
  static Future<AuthResponse> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.fitnessos://login-callback',
    );
  }
  
  static Future<AuthResponse> signInWithApple() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.fitnessos://login-callback',
    );
  }
  
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  // PROFILE METHODS
  
  static Future<Map<String, dynamic>?> getProfile() async {
    if (userId == null) return null;
    
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId!)
        .single();
    
    return response;
  }
  
  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (userId == null) throw Exception('Not authenticated');
    
    await client
        .from('profiles')
        .update(updates)
        .eq('id', userId!);
  }
  
  // WORKOUT METHODS
  
  static Future<void> saveWorkout(Map<String, dynamic> workout) async {
    if (userId == null) throw Exception('Not authenticated');
    
    workout['user_id'] = userId;
    await client.from('workouts').insert(workout);
    
    // Update profile stats
    await client.rpc('increment_workout_stats', params: {
      'user_id': userId,
      'reps': workout['total_reps'] ?? 0,
      'sets': workout['total_sets'] ?? 0,
    });
  }
  
  static Future<List<Map<String, dynamic>>> getWorkouts({int limit = 50}) async {
    if (userId == null) return [];
    
    final response = await client
        .from('workouts')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  // STORAGE METHODS
  
  static Future<String> uploadWorkoutVideo(String filePath) async {
    if (userId == null) throw Exception('Not authenticated');
    
    final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.mp4';
    
    await client.storage
        .from('workout-videos')
        .upload(fileName, File(filePath));
    
    final publicUrl = client.storage
        .from('workout-videos')
        .getPublicUrl(fileName);
    
    return publicUrl;
  }
  
  // ANALYTICS
  
  static Future<void> logEvent(String eventName, Map<String, dynamic> properties) async {
    if (userId == null) return;
    
    await client.from('analytics_events').insert({
      'user_id': userId,
      'event_name': eventName,
      'event_properties': properties,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
```

### Step 3: Initialize in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // ... rest of your init code
  
  runApp(ProviderScope(child: MyApp()));
}
```

---

## 💰 PART 3: REVENUECAT SETUP

### Step 1: Create RevenueCat Account
1. Go to https://www.revenuecat.com
2. Sign up (free up to $10k MRR!)
3. Create new project: "FitnessOS"
4. Add app:
   - Platform: Android
   - Package name: `com.fitnessos.app` (or your package)

### Step 2: Configure Products

1. In RevenueCat Dashboard → Products
2. Create products to match what you'll create in Play Store:
   ```
   - Product ID: fitnessos_premium_monthly
   - Product ID: fitnessos_premium_yearly
   - Product ID: fitnessos_premium_lifetime
   ```

### Step 3: Create Entitlements

1. Go to Entitlements tab
2. Create entitlement: `premium`
3. Attach all your products to this entitlement

### Step 4: Create Offerings

1. Go to Offerings tab
2. Create offering: `default`
3. Add packages:
   - `monthly` → fitnessos_premium_monthly
   - `annual` → fitnessos_premium_yearly
   - `lifetime` → fitnessos_premium_lifetime

### Step 5: Google Play Console Setup

1. Go to Play Console → Monetization → Products
2. Create in-app products:
   ```
   ID: fitnessos_premium_monthly
   Price: $9.99/month
   
   ID: fitnessos_premium_yearly
   Price: $79.99/year (33% savings!)
   
   ID: fitnessos_premium_lifetime
   Price: $199.99 one-time
   ```

3. Go to Monetization → Setup → Service Credentials
4. Create new service account
5. Download JSON key
6. Upload to RevenueCat Dashboard → Google Play → Service Credentials

### Step 6: Add Flutter Dependencies

```yaml
dependencies:
  purchases_flutter: ^6.0.0
```

### Step 7: Create RevenueCat Service

Create `lib/services/revenue_cat_service.dart`:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const String androidApiKey = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const String iosApiKey = 'YOUR_REVENUECAT_IOS_KEY';
  
  static Future<void> initialize(String userId) async {
    await Purchases.setLogLevel(LogLevel.debug);
    
    final configuration = PurchasesConfiguration(
      Platform.isAndroid ? androidApiKey : iosApiKey,
    );
    
    await Purchases.configure(configuration);
    
    // Link RevenueCat to your Supabase user
    await Purchases.logIn(userId);
  }
  
  static Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }
  
  static Future<bool> isPremium() async {
    final customerInfo = await getCustomerInfo();
    return customerInfo.entitlements.all['premium']?.isActive ?? false;
  }
  
  static Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }
  
  static Future<CustomerInfo> purchasePackage(Package package) async {
    return await Purchases.purchasePackage(package);
  }
  
  static Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }
  
  // Sync premium status to Supabase
  static Future<void> syncPremiumStatus() async {
    final isPremium = await RevenueCatService.isPremium();
    await SupabaseService.updateProfile({
      'is_premium': isPremium,
      'subscription_status': isPremium ? 'active' : 'expired',
    });
  }
}
```

### Step 8: Create Paywall Screen

Create `lib/screens/paywall_screen.dart`:

```dart
// I can create a BEAUTIFUL paywall UI if you want! 
// Just ask and I'll make it STUNNING 🔥
```

---

## 🔄 PART 4: WEBHOOK INTEGRATION

### Connect RevenueCat → Supabase

1. In RevenueCat Dashboard → Integrations → Webhooks
2. Add webhook:
   ```
   URL: https://YOUR_PROJECT.supabase.co/functions/v1/revenuecat-webhook
   Authorization: Bearer YOUR_SUPABASE_SERVICE_ROLE_KEY
   ```

3. Create Edge Function in Supabase:

```sql
-- In Supabase Dashboard → Functions → Create new function
-- Name: revenuecat-webhook

CREATE OR REPLACE FUNCTION handle_revenuecat_event()
RETURNS trigger AS $$
BEGIN
  -- Handle subscription events from RevenueCat
  UPDATE public.profiles
  SET 
    is_premium = (NEW.data->>'entitlements'->'premium'->>'is_active')::boolean,
    subscription_status = NEW.data->>'subscription_status',
    subscription_end_date = (NEW.data->>'expires_date')::timestamptz,
    revenue_cat_user_id = NEW.data->>'app_user_id'
  WHERE id = (NEW.data->>'app_user_id')::uuid;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 📊 PART 5: ANALYTICS DASHBOARD

In Supabase, create views for analytics:

```sql
-- Daily Active Users
CREATE VIEW daily_active_users AS
SELECT 
  DATE(created_at) as date,
  COUNT(DISTINCT user_id) as dau
FROM analytics_events
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Popular Exercises
CREATE VIEW popular_exercises AS
SELECT 
  event_properties->>'exercise_name' as exercise,
  COUNT(*) as count
FROM analytics_events
WHERE event_name = 'exercise_completed'
GROUP BY exercise
ORDER BY count DESC
LIMIT 20;

-- Revenue Metrics
CREATE VIEW revenue_metrics AS
SELECT 
  DATE_TRUNC('month', created_at) as month,
  COUNT(DISTINCT user_id) FILTER (WHERE is_premium) as premium_users,
  COUNT(DISTINCT user_id) as total_users,
  (COUNT(DISTINCT user_id) FILTER (WHERE is_premium)::float / COUNT(DISTINCT user_id) * 100) as conversion_rate
FROM profiles
GROUP BY month
ORDER BY month DESC;
```

---

## ✅ FINAL CHECKLIST

### Supabase:
- [ ] Project created
- [ ] Auth providers enabled (Google, Apple, Email)
- [ ] Database tables created with RLS policies
- [ ] Storage buckets created with policies
- [ ] Edge functions set up (if using)
- [ ] Credentials saved securely

### RevenueCat:
- [ ] Account created
- [ ] Products created in Play Console
- [ ] Products configured in RevenueCat
- [ ] Entitlements created
- [ ] Offerings created
- [ ] Service credentials uploaded
- [ ] Webhook configured

### Flutter:
- [ ] `supabase_flutter` added to pubspec.yaml
- [ ] `purchases_flutter` added to pubspec.yaml
- [ ] SupabaseService created
- [ ] RevenueCatService created
- [ ] Initialize both in main.dart
- [ ] Auth flow implemented
- [ ] Paywall screen created
- [ ] Sync premium status on app open

---

## 🚀 READY TO IMPLEMENT?

BRO, SAY THE WORD AND I'LL:
1. Add all the packages
2. Create the services
3. Build the auth screens
4. Build the SICKEST paywall you've ever seen
5. Integrate everything

JUST SAY "DO IT" AND WE GO FULL UNICORN MODE! 🦄🔥💪

