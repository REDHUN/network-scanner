# Privacy Policy Hosting Guide for IP Tools : Network Scanner

## Overview
This guide helps you host the privacy policy for your "IP Tools : Network Scanner" app to meet Google Play Store requirements.

## Files Created
- `privacy_policy.html` - Complete privacy policy webpage
- This hosting guide

## Hosting Options

### Option 1: GitHub Pages (Free & Recommended)
1. Create a new GitHub repository (e.g., `ip-tools-privacy-policy`)
2. Upload the `privacy_policy.html` file
3. Enable GitHub Pages in repository settings
4. Your privacy policy will be available at: `https://yourusername.github.io/ip-tools-privacy-policy/privacy_policy.html`

### Option 2: Netlify (Free)
1. Go to [netlify.com](https://netlify.com)
2. Drag and drop the `privacy_policy.html` file
3. Get your free URL (e.g., `https://random-name.netlify.app/privacy_policy.html`)

### Option 3: Firebase Hosting (Free)
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Create a new Firebase project
3. Initialize hosting: `firebase init hosting`
4. Upload the HTML file
5. Deploy: `firebase deploy`

### Option 4: Your Own Domain
If you have a website, simply upload the `privacy_policy.html` file to your web server.

## Google Play Store Requirements

### What You Need:
1. **Privacy Policy URL**: The public URL where your privacy policy is hosted
2. **Accessible**: Must be publicly accessible (not behind login)
3. **Complete**: Must cover all data collection and permissions used by your app

### Where to Add in Play Console:
1. Go to Google Play Console
2. Select your app
3. Navigate to "Policy" → "App content"
4. Add your privacy policy URL in the "Privacy Policy" section

## Important Notes

### Before Publishing:
1. **Update Contact Information**: Replace `[Your Email Address]` and `[Your Name/Company]` in the privacy policy
2. **Review Permissions**: Ensure all permissions used by your app are covered
3. **Test the URL**: Make sure the privacy policy loads correctly
4. **Keep Updated**: Update the policy if you change app functionality

### Key Features Covered:
- ✅ Location permission (required for WiFi access)
- ✅ Network access permissions
- ✅ Local data storage
- ✅ No data transmission to external servers
- ✅ Device scanning functionality
- ✅ Router history storage
- ✅ User rights and data control

## Privacy Policy Highlights

Your privacy policy clearly states:
- **Local Storage Only**: All data stays on the user's device
- **No External Transmission**: No data sent to servers or third parties
- **Transparent Permissions**: Clear explanation of why each permission is needed
- **User Control**: Users can delete data and control permissions
- **No Location Tracking**: Location permission used only for WiFi access

## Quick Setup Steps

1. **Choose a hosting option** (GitHub Pages recommended)
2. **Upload the privacy_policy.html file**
3. **Update contact information** in the HTML file
4. **Get the public URL**
5. **Add URL to Google Play Console**
6. **Test that it loads correctly**

## Example URLs
After hosting, your privacy policy URL might look like:
- `https://yourusername.github.io/ip-tools-privacy-policy/privacy_policy.html`
- `https://your-site.netlify.app/privacy_policy.html`
- `https://yourwebsite.com/privacy_policy.html`

## Support
If you need help with hosting or have questions about the privacy policy content, the policy covers all the standard requirements for network scanning apps on the Google Play Store.