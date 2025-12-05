-- SharedVisions Supabase Setup
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/YOUR_PROJECT/sql

-- 1. PROFILES TABLE (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. USER PHOTOS (for AI training)
CREATE TABLE IF NOT EXISTS user_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. GROUPS
CREATE TABLE IF NOT EXISTS groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  invite_code TEXT UNIQUE,
  created_by UUID REFERENCES profiles(id),
  aesthetic_profile JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. GROUP MEMBERS
CREATE TABLE IF NOT EXISTS group_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- 5. VISIONS
CREATE TABLE IF NOT EXISTS visions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  target_members UUID[] DEFAULT '{}',
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. GENERATED IMAGES
CREATE TABLE IF NOT EXISTS generated_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vision_id UUID REFERENCES visions(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  prompt_used TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE visions ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_images ENABLE ROW LEVEL SECURITY;

-- PROFILES: Users can read all profiles, update their own
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- USER PHOTOS: Users can manage their own photos
CREATE POLICY "Users can view own photos" ON user_photos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own photos" ON user_photos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own photos" ON user_photos FOR DELETE USING (auth.uid() = user_id);
-- Group members can view each other's photos
CREATE POLICY "Group members can view photos" ON user_photos FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid() AND gm2.user_id = user_photos.user_id
  )
);

-- GROUPS: Members can view their groups
CREATE POLICY "Members can view groups" ON groups FOR SELECT USING (
  EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid())
);
CREATE POLICY "Anyone can create groups" ON groups FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Owners can update groups" ON groups FOR UPDATE USING (auth.uid() = created_by);

-- GROUP MEMBERS: Members can view group members
CREATE POLICY "Members can view group members" ON group_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = group_members.group_id AND gm.user_id = auth.uid())
);
CREATE POLICY "Users can join groups" ON group_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave groups" ON group_members FOR DELETE USING (auth.uid() = user_id);

-- VISIONS: Group members can view/create visions
CREATE POLICY "Group members can view visions" ON visions FOR SELECT USING (
  EXISTS (SELECT 1 FROM group_members WHERE group_id = visions.group_id AND user_id = auth.uid())
);
CREATE POLICY "Group members can create visions" ON visions FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM group_members WHERE group_id = visions.group_id AND user_id = auth.uid())
);
CREATE POLICY "Vision creators can update" ON visions FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Vision creators can delete" ON visions FOR DELETE USING (auth.uid() = created_by);

-- GENERATED IMAGES: Group members can view/create images
CREATE POLICY "Group members can view images" ON generated_images FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM visions v
    JOIN group_members gm ON v.group_id = gm.group_id
    WHERE v.id = generated_images.vision_id AND gm.user_id = auth.uid()
  )
);
CREATE POLICY "Group members can insert images" ON generated_images FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM visions v
    JOIN group_members gm ON v.group_id = gm.group_id
    WHERE v.id = generated_images.vision_id AND gm.user_id = auth.uid()
  )
);

-- ============================================
-- FUNCTION: Auto-create profile on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- STORAGE BUCKETS (run separately if needed)
-- ============================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('user-photos', 'user-photos', false);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('generated-images', 'generated-images', true);

