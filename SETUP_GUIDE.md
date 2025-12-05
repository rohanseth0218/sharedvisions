# SharedVisions Setup Guide

Step-by-step instructions for setting up Supabase and Google Gemini.

## Part 1: Supabase Setup

### Step 1: Create Supabase Account
1. Go to https://supabase.com
2. Click **"Start your project"** or **"Sign Up"**
3. Sign up with GitHub (recommended) or email
4. Verify your email if needed

### Step 2: Create a New Project
1. Click **"New Project"** in the dashboard
2. Fill in:
   - **Name**: `sharedvisions` (or your choice)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to you (e.g., `US East`)
   - **Pricing Plan**: Free tier is fine for testing
3. Click **"Create new project"**
4. Wait 2-3 minutes for project to initialize

### Step 3: Get Your API Keys
1. In your project dashboard, go to **Settings** (gear icon) → **API**
2. You'll see two important values:
   - **Project URL**: `https://xxxxx.supabase.co` (copy this)
   - **anon public key**: `eyJhbGc...` (long string, copy this)
3. Save both - you'll need them for `Secrets.swift`

### Step 4: Set Up Database Tables
1. In Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New query"**
3. Copy and paste the entire contents of `supabase-setup.sql` from this repo
4. Click **"Run"** (or press Cmd+Enter)
5. You should see "Success. No rows returned" - this is good!

### Step 5: Create Storage Buckets
1. Go to **Storage** (left sidebar)
2. Click **"New bucket"**
3. Create these three buckets (one at a time):

   **Bucket 1: `user-photos`**
   - Name: `user-photos`
   - Public bucket: ✅ **Check this**
   - Click **"Create bucket"**

   **Bucket 2: `generated-images`**
   - Name: `generated-images`
   - Public bucket: ✅ **Check this**
   - Click **"Create bucket"**

   **Bucket 3: `avatars`**
   - Name: `avatars`
   - Public bucket: ✅ **Check this**
   - Click **"Create bucket"**

### Step 6: Set Up Storage Policies (Important!)
For each bucket (`user-photos`, `generated-images`, `avatars`):

1. Click on the bucket name
2. Go to **"Policies"** tab
3. Click **"New Policy"**
4. Select **"For full customization"**
5. Use this policy (replace `BUCKET_NAME` with actual bucket name):

```sql
-- Policy name: "Users can upload their own files"
-- Policy definition:
(user_id() = (storage.foldername(name))[1]::uuid)

-- Policy name: "Anyone can view public files"
-- Policy definition:
true
```

**OR use the simpler approach:**
- For each bucket, create a policy:
  - **Policy name**: "Public read, authenticated write"
  - **Allowed operation**: SELECT, INSERT, UPDATE, DELETE
  - **Policy definition**: 
    ```sql
    true
    ```
  - **Check "Use RLS"**: ✅

### Step 7: Enable Email Auth
1. Go to **Authentication** → **Providers**
2. Make sure **Email** is enabled (should be by default)
3. Optionally configure:
   - **Confirm email**: Toggle off for testing (on for production)
   - **Email templates**: Can customize later

---

## Part 2: Google Gemini Setup

### Step 1: Get Gemini API Key
1. Go to https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Choose:
   - **Create API key in new project** (recommended for first time)
   - OR select existing project
5. Copy the API key (looks like: `AIza...`)
6. **Important**: Save this key - you won't be able to see it again!

### Step 2: Enable Imagen API (for Image Generation)
**Note**: As of now, Gemini's Imagen API may require:
- Google Cloud Console access
- Enabling the Imagen API
- Potentially a paid account

**Option A: Use Gemini for Text Generation Only**
- The app can use Gemini to enhance prompts
- For actual image generation, you may need to integrate a different service initially

**Option B: Enable Imagen API**
1. Go to https://console.cloud.google.com
2. Create a new project (or select existing)
3. Go to **APIs & Services** → **Library**
4. Search for **"Imagen API"** or **"Generative Language API"**
5. Click **"Enable"**
6. Make sure your API key has access to this API

### Step 3: Test Your API Key (Optional)
You can test if your key works:

```bash
curl https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_API_KEY \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

---

## Part 3: Configure the iOS App

### Step 1: Copy Secrets Template
```bash
cd ~/sharedvisions
cp Secrets.example.swift SharedVisions/SharedVisions/Utilities/Secrets.swift
```

### Step 2: Edit Secrets.swift
Open `SharedVisions/SharedVisions/Utilities/Secrets.swift` and replace:

```swift
enum Secrets {
    // From Supabase Settings > API
    static let supabaseURL = "https://YOUR_PROJECT_ID.supabase.co"
    static let supabaseAnonKey = "eyJhbGc...your_anon_key_here"
    
    // From Google AI Studio
    static let geminiAPIKey = "AIza...your_gemini_key_here"
}
```

**Where to find these:**
- `supabaseURL`: Supabase Dashboard → Settings → API → Project URL
- `supabaseAnonKey`: Supabase Dashboard → Settings → API → Project API keys → `anon` `public`
- `geminiAPIKey`: https://aistudio.google.com/app/apikey

---

## Verification Checklist

### Supabase ✅
- [ ] Project created
- [ ] API keys copied (URL and anon key)
- [ ] Database tables created (ran `supabase-setup.sql`)
- [ ] Storage buckets created (`user-photos`, `generated-images`, `avatars`)
- [ ] Storage policies configured
- [ ] Email auth enabled

### Google Gemini ✅
- [ ] API key created
- [ ] API key copied
- [ ] (Optional) Imagen API enabled if using image generation

### iOS App ✅
- [ ] `Secrets.swift` created and configured
- [ ] All three keys filled in correctly
- [ ] Xcode project created
- [ ] Swift packages added (Supabase, GoogleGenerativeAI)

---

## Troubleshooting

### Supabase Issues

**"Permission denied" errors:**
- Check RLS policies are set correctly
- Make sure storage buckets are public
- Verify user is authenticated

**"Table doesn't exist" errors:**
- Make sure you ran the SQL setup script
- Check SQL Editor for any errors
- Verify tables appear in Table Editor

**Storage upload fails:**
- Check bucket policies allow INSERT
- Verify bucket is public
- Check file size limits (5MB default)

### Gemini Issues

**"API key invalid":**
- Double-check the key is copied correctly (no extra spaces)
- Make sure you're using the key from AI Studio, not Cloud Console
- Verify the API is enabled in your project

**"Quota exceeded":**
- Free tier has rate limits
- Check usage in Google Cloud Console
- Consider upgrading if needed

**Image generation not working:**
- Imagen API may require separate setup
- Check if Imagen is enabled in Cloud Console
- Consider using a different image generation service initially

---

## Next Steps

1. ✅ Complete Supabase setup
2. ✅ Complete Google Gemini setup
3. ✅ Configure `Secrets.swift` in Xcode
4. ✅ Build and run the app in Xcode
5. ✅ Test signup/login flow
6. ✅ Test creating groups and visions

---

## Support Resources

- **Supabase Docs**: https://supabase.com/docs
- **Supabase Discord**: https://discord.supabase.com
- **Gemini API Docs**: https://ai.google.dev/docs
- **Google AI Studio**: https://aistudio.google.com

