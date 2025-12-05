# Quick Setup Reference

## Supabase (5 minutes)

1. **Sign up**: https://supabase.com → Start project
2. **Create project**: Name it, choose region, set password
3. **Get keys**: Settings → API → Copy:
   - Project URL: `https://xxxxx.supabase.co`
   - anon key: `eyJhbGc...`
4. **Run SQL**: SQL Editor → Paste `supabase-setup.sql` → Run
5. **Create buckets**: Storage → Create 3 buckets:
   - `user-photos` (public ✅)
   - `generated-images` (public ✅)
   - `avatars` (public ✅)

## Google Gemini (2 minutes)

1. **Get API key**: https://aistudio.google.com/app/apikey
2. **Sign in** with Google account
3. **Create API key** → Copy it: `AIza...`
4. **Save it** (can't view again!)

## iOS App Config (1 minute)

1. Copy secrets:
   ```bash
   cp Secrets.example.swift SharedVisions/SharedVisions/Utilities/Secrets.swift
   ```

2. Edit `Secrets.swift`:
   ```swift
   static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
   static let supabaseAnonKey = "YOUR_ANON_KEY"
   static let geminiAPIKey = "YOUR_GEMINI_KEY"
   ```

## That's it! 🎉

See `SETUP_GUIDE.md` for detailed instructions.

