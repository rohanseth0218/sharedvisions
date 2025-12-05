# SharedVisions User Workflow

Complete user journey from first launch to creating shared visions.

## 📱 Complete User Journey

### Phase 1: First Launch & Onboarding

**1. App Launch**
- User opens the app
- Sees beautiful onboarding screen with gradient background
- Features highlighted:
  - ✨ Connect - Build shared vision board together
  - ✨ Visualize - AI brings dreams to life
  - ✨ Remember - Keep aspirations close

**2. Sign Up / Sign In**
- User taps "Get Started"
- Two options:
  - **New User**: Sign Up
    - Enter full name
    - Enter email
    - Create password (min 8 chars)
    - Confirm password
    - Create account
  - **Existing User**: Sign In
    - Enter email
    - Enter password
    - Sign in
    - (Optional) Forgot password flow

**3. Profile Setup (Optional)**
- After signup, user lands in main app
- Can immediately start using, or set up profile first

---

### Phase 2: Group Creation & Joining

**4. Create or Join a Group**
- User navigates to **Groups** tab
- Two options:

  **Option A: Create Group**
  - Tap "Create Group" button
  - Enter group name (e.g., "Our Dreams", "Sarah & John")
  - System generates unique invite code (e.g., "ABC123")
  - Group created, user is owner
  - Can share invite code with partner

  **Option B: Join Group**
  - Tap "Join with Code"
  - Enter 6-character invite code
  - Join existing group
  - Now member of that group

**5. Group Management**
- View group details
- See all members
- Share invite code (copy or share link)
- View group visions
- Leave group (if needed)

---

### Phase 3: Photo Upload (For AI)

**6. Upload Reference Photos**
- Navigate to **Profile** tab
- Tap "Add" in "My Photos" section
- Two options:
  - **Gallery**: Select from photo library
  - **Camera**: Take new photo
- Upload multiple photos (up to 10)
- Set one as "Primary" photo
- Photos used by AI to personalize generated images

**Photo Tips Shown:**
- ✨ Clear view of your face
- ✨ Good lighting
- ✨ Just you in the photo
- ✨ Front-facing works best

---

### Phase 4: Creating Visions

**7. Create a Vision**
- Navigate to **Feed** or **Gallery** tab
- Tap "+" button or "Create Vision"
- Fill in vision form:
  - **Select Group**: Choose which group this vision is for
  - **Vision Title**: e.g., "Beach vacation in Maldives"
  - **Description** (optional): More details about the vision
  - **Image Style**: Choose from:
    - 📷 Realistic - Photorealistic, natural lighting
    - 🎨 Artistic - Artistic interpretation, painterly
    - 🎬 Cinematic - Dramatic lighting, movie-like
    - ☁️ Dreamy - Soft focus, ethereal
  - **Generate immediately**: Toggle on/off
- Tap "Create Vision"

**8. AI Image Generation**
- If "Generate immediately" is ON:
  - Vision status changes to "Generating..."
  - AI processes the vision description
  - Uses uploaded photos of group members
  - Enhances prompt with Gemini
  - Generates image with Imagen API
  - Image appears in vision
  - Status changes to "Completed"
- If OFF:
  - Vision saved as "Pending"
  - User can generate image later by tapping vision

---

### Phase 5: Viewing & Managing Visions

**9. Feed View (News Feed Style)**
- Scroll through visions chronologically
- See visions from all user's groups
- Each vision shows:
  - Group avatar/icon
  - Vision title
  - Creation date (relative time)
  - Status badge (Pending/Generating/Completed/Failed)
  - Generated image (if completed)
  - Description
  - Actions:
    - ❤️ Favorite/Unfavorite
    - 💬 Comment (future)
    - 📤 Share
    - 🔄 Regenerate (if completed)

**10. Gallery View (Grid Layout)**
- Visual grid of all visions
- 2-column layout
- Each card shows:
  - Generated image (or placeholder)
  - Status overlay for non-completed visions
- Tap any vision to see details

**11. Vision Detail View**
- Full-screen image carousel (if multiple images)
- Vision title and description
- Status indicator
- Creation date
- Actions:
  - Generate/Regenerate image
  - Share image
  - Delete vision
  - Favorite/Unfavorite

---

### Phase 6: Ongoing Usage

**12. Daily Usage Flow**
1. Open app → See Feed with latest visions
2. View partner's new visions
3. Create new vision together
4. Regenerate images with different styles
5. Favorite best images
6. Share visions with friends/family

**13. Group Collaboration**
- Both partners can create visions in shared group
- All visions visible to all group members
- Can create visions for specific members (future feature)
- Default: visions are for all group members

**14. Profile Management**
- Update profile picture
- Upload more reference photos
- View stats (photos, visions, groups)
- Settings:
  - Edit profile
  - Notifications
  - Help & Support
  - Sign out

---

## 🔄 Key User Flows

### Flow 1: New User Journey
```
Launch App → Onboarding → Sign Up → Create Group → 
Upload Photos → Create Vision → Generate Image → View in Feed
```

### Flow 2: Existing User Daily Use
```
Open App → View Feed → Create Vision → Generate → Share
```

### Flow 3: Joining Partner's Group
```
Open App → Sign In → Join Group (with code) → 
Upload Photos → View Partner's Visions → Create Together
```

### Flow 4: Regenerating Images
```
View Vision → Tap Regenerate → Choose Style → 
New Image Generated → Compare Styles
```

---

## 🎯 Key Features by Tab

### Feed Tab
- **Purpose**: News feed of all visions
- **Content**: Chronological list of visions from all groups
- **Actions**: Create, view, favorite, share, regenerate

### Gallery Tab
- **Purpose**: Visual grid of all visions
- **Content**: 2-column grid with images
- **Actions**: Browse visually, tap to view details

### Groups Tab
- **Purpose**: Manage groups and members
- **Content**: List of user's groups
- **Actions**: Create, join, view details, share invite codes

### Profile Tab
- **Purpose**: User settings and photo management
- **Content**: Profile info, uploaded photos, stats
- **Actions**: Upload photos, edit profile, settings, sign out

---

## 💡 User Experience Highlights

**Onboarding**
- Beautiful, inspiring design
- Clear value proposition
- Easy signup flow

**Group Creation**
- Simple, intuitive
- Instant invite code generation
- Easy sharing

**Vision Creation**
- Flexible (can generate immediately or later)
- Multiple style options
- Clear, simple form

**Image Generation**
- Transparent status updates
- Multiple regeneration options
- High-quality AI images

**Viewing**
- Two viewing modes (feed vs gallery)
- Smooth navigation
- Rich interactions (favorite, share, etc.)

---

## 🔮 Future Enhancements (Not Yet Implemented)

- Comments on visions
- Notifications for new visions
- Vision editing after creation
- Multiple images per vision
- Vision categories/tags
- Sharing to social media
- Export visions as photos
- Vision reminders/goals tracking

