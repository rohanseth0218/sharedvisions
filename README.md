# SharedVisions

An iOS app for couples to build shared visions together and bring their dreams to life with AI-generated imagery.

## Features

- **Shared Vision Boards**: Create and share goals with your partner
- **AI Image Generation**: Turn your dreams into visualizations using Google Gemini
- **Photo Library**: Upload photos for personalized AI generation
- **Groups**: Create couples or family groups to share visions
- **Gallery Views**: Browse visions in grid or feed layouts

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Supabase account
- Google Gemini API key

## Setup Instructions

### 1. Clone the Repository

```bash
git clone git@github.com:rohanseth0218/sharedvisions.git
cd sharedvisions
```

### 2. Create Xcode Project

Since Xcode projects can't be committed cleanly to git, you'll need to create one:

1. Open Xcode
2. File > New > Project
3. Select **iOS > App**
4. Configure:
   - Product Name: `SharedVisions`
   - Team: Your Apple ID
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Save to: `~/sharedvisions/SharedVisions`
6. Drag the existing source folders into the project navigator

### 3. Add Swift Package Dependencies

In Xcode:
1. File > Add Package Dependencies
2. Add these packages:

| Package | URL |
|---------|-----|
| Supabase | `https://github.com/supabase/supabase-swift` |
| GoogleGenerativeAI | `https://github.com/google/generative-ai-swift` |

### 4. Configure API Keys

1. Copy the secrets template:
   ```bash
   cp Secrets.example.swift SharedVisions/SharedVisions/Utilities/Secrets.swift
   ```

2. Edit `Secrets.swift` with your actual API keys:
   - **Supabase URL**: Get from Supabase Dashboard > Settings > API
   - **Supabase Anon Key**: Get from Supabase Dashboard > Settings > API
   - **Gemini API Key**: Get from [Google AI Studio](https://aistudio.google.com/app/apikey)

### 5. Set Up Supabase

Create these tables in your Supabase dashboard (SQL Editor):

```sql
-- Run the SQL from the setup guide or use the Supabase dashboard
-- Tables needed: profiles, user_photos, groups, group_members, visions, generated_images
```

Create storage buckets:
- `user-photos` (public)
- `generated-images` (public)
- `avatars` (public)

### 6. Run the App

1. Select a simulator (e.g., iPhone 15 Pro)
2. Press `Cmd + R` to build and run

## Project Structure

```
SharedVisions/
├── App/                    # App entry point
├── Core/                   # Feature modules
│   ├── Authentication/     # Login, signup, auth flow
│   ├── Groups/            # Group management
│   ├── Visions/           # Vision creation and display
│   └── Profile/           # User profile and photos
├── Models/                # Data models
├── Services/              # API services
├── Components/            # Reusable UI components
├── Extensions/            # Swift extensions
└── Utilities/             # Constants and helpers
```

## Testing

### Simulator Testing (Free)
- No Apple Developer account needed
- Works with all app features
- Camera simulation available

### Device Testing
- Requires Apple Developer account ($99/year)
- Or use free provisioning (7-day certificates)
- Settings > General > VPN & Device Management > Trust developer

## API Services Used

### Supabase
- Authentication (email/password)
- PostgreSQL database
- File storage
- Real-time subscriptions (future)

### Google Gemini
- Imagen API for image generation
- Text generation for prompt enhancement

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file

## Support

For issues or questions, open a GitHub issue.

