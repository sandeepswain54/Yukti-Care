# SENSITIVE DATA ANALYSIS - DO NOT PUSH TO GITHUB

This document identifies all files containing API keys, credentials, and other sensitive data that should NOT be committed to GitHub.

---

## 🔴 CRITICAL - FILES WITH SENSITIVE DATA

### 1. **firebase_config.json** (Location: `/android/app/google-services.json`)
**SEVERITY: CRITICAL**
- **Content**: Firebase project configuration with sensitive credentials
- **Sensitive Data Found**:
  - `project_number`: "904768071492"
  - `project_id`: "researchapp-ab483"
  - `storage_bucket`: "researchapp-ab483.appspot.com"
  - `mobilesdk_app_id`: Multiple IDs
  - **API_KEY**: "AIzaSyBsGJvROfXQPnVZiP1rm5fcqaD66e45Qas" (Google API Key)
  
- **Impact**: This file contains the Google API key which can be used to access your Firebase services
- **Action**: Add `/android/app/google-services.json` to `.gitignore` IMMEDIATELY

---

### 2. **keystore.properties** (Location: `/android/keystore.properties`)
**SEVERITY: CRITICAL**
- **Content**: Android keystore credentials
- **Sensitive Data Found**:
  - `storePassword=20242025`
  - `keyPassword=20242025`
  - `keyAlias=upload`
  - `storeFile=D:/FlutterDev/Service app/upload-keystore.jks` (File path + credentials)

- **Impact**: These credentials can be used to sign and publish unauthorized APK files
- **Action**: Add `/android/keystore.properties` to `.gitignore` IMMEDIATELY

---

### 3. **local.properties** (Location: `/android/local.properties`)
**SEVERITY: HIGH**
- **Content**: Local Android SDK configuration
- **Sensitive Data Found**:
  - `sdk.dir=C:\\Users\\sande\\AppData\\Local\\Android\\sdk` (Local file paths)
  - `flutter.sdk=D:\\FlutterDev\\sdk\\flutter` (Local file paths)

- **Impact**: Exposes system file paths and user information
- **Action**: Add `/android/local.properties` to `.gitignore` (Already standard practice)

---

### 4. **market_service.dart** (Location: `/lib/services/market_service.dart`)
**SEVERITY: HIGH**
- **Content**: Hardcoded API key for Government of India Data API
- **Sensitive Data Found**:
  - **API Key**: `579b464db66ec23bdd000001a4750d8e9abf4c2260159520aca95751`
  - **Base URL**: `https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070`

- **Line**: Line 7
```dart
static const String _apiKey = "579b464db66ec23bdd000001a4750d8e9abf4c2260159520aca95751";
```

- **Impact**: This API key can be revoked by the service provider or abused
- **Action Required**:
  - Remove hardcoded API key immediately
  - Move to environment variables or `.env` file
  - Rotate the API key in the data.gov.in dashboard

---

### 5. **.env file** (Location: `/assets/.env`)
**SEVERITY: CRITICAL**
- **Content**: Environment variables loaded at runtime
- **Sensitive Data**:
  - `TOGETHER_API_KEY` - Together AI API key (referenced in code but likely contains actual key in the file)
  
- **Location in Code**: 
  - [main.dart](main.dart#L63-L71) - loads from `assets/.env`
  - [chat_service.dart](lib/Chat_Bot/chat_service.dart#L12) - uses TOGETHER_API_KEY

- **Impact**: Exposes AI service API credentials
- **Action**: Add `/assets/.env` to `.gitignore` IMMEDIATELY

---

## 📋 FILES THAT REQUIRE ATTENTION

### Files Using Firebase Credentials (Indirect Access)
These files don't contain raw credentials but depend on `google-services.json`:

1. **[lib/views/splash_screen.dart](lib/views/splash_screen.dart)** - FirebaseAuth initialization
2. **[lib/views/login.dart](lib/views/login.dart)** - Firebase authentication
3. **[lib/views/userregister.dart](lib/views/userregister.dart)** - User registration with Firebase
4. **[lib/view_model/posting_view_model.dart](lib/view_model/posting_view_model.dart)** - Firestore database access
5. **[lib/Firebase_Distributor/product_upload_screen.dart](lib/Firebase_Distributor/product_upload_screen.dart)** - Firebase Storage uploads
6. **[lib/views/Host_Screens/booking.dart](lib/views/Host_Screens/booking.dart)** - Firestore queries

**Risk**: If `google-services.json` is exposed, attackers can perform unauthorized operations through these files.

---

## 🚨 RECOMMENDED ACTIONS

### Immediate Actions (CRITICAL)

1. **Create/Update `.gitignore`**:
```
# Sensitive Configuration Files
android/app/google-services.json
android/keystore.properties
android/local.properties
assets/.env
.env
.env.local
.env.*.local
```

2. **Remove google-services.json from Git History**:
```bash
git rm --cached android/app/google-services.json
git commit -m "Remove sensitive google-services.json from tracking"
```

3. **Remove keystore.properties from Git History**:
```bash
git rm --cached android/keystore.properties
git commit -m "Remove sensitive keystore credentials from tracking"
```

4. **Rotate All Exposed API Keys**:
   - **Google API Key**: Disable/delete in Google Cloud Console
   - **data.gov.in API Key**: Regenerate in data.gov.in dashboard
   - **Together AI API Key**: Regenerate in Together AI dashboard

---

### Short-term Actions (IMPORTANT)

1. **Move API Keys to Environment Variables**:
   - Create `assets/.env` (if not already created)
   - Add `TOGETHER_API_KEY=your_actual_key_here`
   - Add `MARKET_API_KEY=579b464db66ec23bdd000001a4750d8e9abf4c2260159520aca95751` (then remove from code)

2. **Update [lib/services/market_service.dart](lib/services/market_service.dart)**:
```dart
// BEFORE (WRONG):
static const String _apiKey = "579b464db66ec23bdd000001a4750d8e9abf4c2260159520aca95751";

// AFTER (CORRECT):
static String _apiKey = dotenv.env['MARKET_API_KEY'] ?? '';
```

3. **Document All API Keys**:
   - Create a private document (NOT in Git) listing all API keys
   - Store them securely (e.g., in a password manager)
   - Share with team members securely

4. **Set up .env.example** (Safe template for developers):
```
# assets/.env.example (SAFE TO COMMIT)
TOGETHER_API_KEY=your_key_here
MARKET_API_KEY=your_key_here
```

---

### Long-term Actions (BEST PRACTICES)

1. **Use Secret Management Service**:
   - Firebase Remote Config for Firebase credentials
   - AWS Secrets Manager or similar for other APIs
   - Google Secret Manager for Google-related APIs

2. **Implement CI/CD Best Practices**:
   - Store secrets in CI/CD environment variables
   - Never include secrets in build scripts
   - Use GitHub Secrets for sensitive data

3. **Code Review Checklist**:
   - Never hardcode API keys
   - Always use environment variables or secure vaults
   - Review all commits before pushing

4. **Security Scanning**:
   - Use GitHub's secret scanning feature
   - Implement pre-commit hooks to detect secrets
   - Use tools like `detect-secrets` or `git-secrets`

---

## 📊 SUMMARY TABLE

| File | Type | Severity | Sensitive Data | Action |
|------|------|----------|-----------------|--------|
| `android/app/google-services.json` | Config | 🔴 CRITICAL | Google API Key, Firebase Config | Add to .gitignore, Remove from history |
| `android/keystore.properties` | Config | 🔴 CRITICAL | Keystore passwords, file paths | Add to .gitignore, Remove from history |
| `lib/services/market_service.dart` | Code | 🟠 HIGH | Hardcoded API Key (data.gov.in) | Extract to .env, Rotate key |
| `assets/.env` | Config | 🔴 CRITICAL | TOGETHER_API_KEY | Add to .gitignore |
| `android/local.properties` | Config | 🟡 MEDIUM | System file paths | Add to .gitignore (standard) |

---

## 🔒 COMPLIANCE CHECKLIST

- [ ] All sensitive data has been identified
- [ ] `.gitignore` has been updated
- [ ] Sensitive files removed from Git history
- [ ] All exposed API keys rotated
- [ ] API keys moved to environment variables
- [ ] `.env.example` created for team
- [ ] Security scanning enabled (GitHub)
- [ ] Team notified of security changes
- [ ] Documentation updated with security guidelines

---

**Last Updated**: December 15, 2025
**Status**: ⚠️ ACTION REQUIRED - Sensitive data detected
