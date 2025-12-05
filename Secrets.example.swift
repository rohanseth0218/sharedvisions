import Foundation

/// API Keys and Configuration
/// 
/// SETUP INSTRUCTIONS:
/// 1. Copy this file to SharedVisions/SharedVisions/Utilities/Secrets.swift
/// 2. Replace the placeholder values with your actual API keys
/// 3. The Secrets.swift file is gitignored and will not be committed
///
/// GETTING YOUR KEYS:
/// - Supabase: https://supabase.com/dashboard/project/_/settings/api
/// - Gemini: https://aistudio.google.com/app/apikey

enum Secrets {
    /// Supabase project URL
    /// Found in: Supabase Dashboard > Settings > API > Project URL
    static let supabaseURL = "https://YOUR_PROJECT_ID.supabase.co"
    
    /// Supabase anonymous/public key
    /// Found in: Supabase Dashboard > Settings > API > Project API keys > anon/public
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
    
    /// Google Gemini API key
    /// Get one at: https://aistudio.google.com/app/apikey
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY"
}

