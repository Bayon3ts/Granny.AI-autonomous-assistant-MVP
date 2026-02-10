# Fix Guide: OpenAI Realtime API 401 Unauthorized Error

## Problem Analysis

The error you're experiencing is:
```
aiohttp.client_exceptions.WSServerHandshakeError: 401, message='Invalid response status',
url='wss://api.openai.com/v1/realtime?model=gpt-realtime'
```

**Root Cause**: The OpenAI Realtime API is returning a 401 (Unauthorized) error, which means:
- The API key is missing, invalid, or not properly configured
- The API key doesn't have access to the Realtime API
- The API key format is incorrect

## Code Fixes Applied

### 1. ✅ Fixed Duplicate `session.start()` Call
   - **Issue**: The code had two `session.start()` calls which would cause conflicts
   - **Fix**: Removed the duplicate call

### 2. ✅ Added API Key Validation and Explicit Passing
   - **Issue**: API key might not be properly loaded or passed to RealtimeModel
   - **Fix**: 
     - Added validation to check if `OPENAI_API_KEY` exists before attempting connection
     - Explicitly pass the API key to `RealtimeModel(api_key=openai_api_key)`
     - Ensure the environment variable is set in `os.environ` for libraries that read directly from environment
     - Added better error messages and debugging output

### 3. ✅ Created Helper Scripts
   - **Created**: `check_env.py` - Verifies environment configuration
   - **Created**: `test_openai_key.py` - Tests if API key is valid

## Steps to Fix the 401 Error

### Step 1: Create/Update `.env.local` File

Navigate to the `Granny-voice` directory and create or update `.env.local`:

```bash
cd Granny-voice
```

Create the file with the following content:

```env
# OpenAI API Configuration
OPENAI_API_KEY=sk-your-actual-openai-api-key-here

# LiveKit Configuration (if not already present)
LIVEKIT_URL=wss://your-livekit-server-url
LIVEKIT_API_KEY=your-livekit-api-key
LIVEKIT_API_SECRET=your-livekit-api-secret
```

### Step 2: Get Your OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign in or create an account
3. Navigate to **API Keys** section: https://platform.openai.com/api-keys
4. Click **"Create new secret key"**
5. Copy the key (it starts with `sk-`)
6. **Important**: Make sure your API key has access to the Realtime API
   - The Realtime API may require a specific subscription tier
   - Check your OpenAI account billing and plan

### Step 3: Verify API Key Format

Your API key should:
- Start with `sk-`
- Be approximately 51 characters long
- Not have any spaces or line breaks
- Example: `sk-proj-abc123def456ghi789jkl012mno345pqr678stu901vwx234yz`

### Step 4: Check API Key Permissions

The OpenAI Realtime API requires:
- An active OpenAI account
- Sufficient API credits/quota
- Access to the `gpt-realtime` model (may require specific subscription)

To verify:
1. Test your API key with a simple curl command:
   ```bash
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer sk-your-api-key-here"
   ```
2. If this works, your key is valid
3. Check if you can access Realtime API specifically

### Step 5: Set Environment Variable (Alternative Method)

If `.env.local` doesn't work, you can set the environment variable directly:

**Windows (PowerShell):**
```powershell
$env:OPENAI_API_KEY="sk-your-api-key-here"
```

**Windows (Command Prompt):**
```cmd
set OPENAI_API_KEY=sk-your-api-key-here
```

**Linux/Mac:**
```bash
export OPENAI_API_KEY=sk-your-api-key-here
```

### Step 6: Verify the Fix

1. Make sure your `.env.local` file is in the `Granny-voice` directory
2. Restart your agent server
3. The validation code will now show a clear error if the key is missing
4. If the key is set correctly, the 401 error should be resolved

## Troubleshooting

### If you still get 401 after setting the key:

1. **Check file location**: Ensure `.env.local` is in the `Granny-voice` directory (same folder as `agent.py`)

2. **Check for typos**: Verify the variable name is exactly `OPENAI_API_KEY` (case-sensitive)

3. **Check for quotes**: Don't wrap the API key in quotes in `.env.local`:
   ```env
   # ❌ Wrong
   OPENAI_API_KEY="sk-..."
   
   # ✅ Correct
   OPENAI_API_KEY=sk-...
   ```

4. **Restart the application**: Environment variables are loaded at startup

5. **Check API key validity**: Test the key with OpenAI's API directly

6. **Check billing/quota**: Ensure your OpenAI account has:
   - Active billing method
   - Sufficient credits
   - Access to Realtime API features

7. **Check API key permissions**: Some organizations restrict which APIs can be accessed

### If you get "OPENAI_API_KEY environment variable is required":

- The validation is working! This means the key is not being loaded
- Double-check the `.env.local` file exists and is in the correct location
- Verify the file is named exactly `.env.local` (not `.env.local.txt` or similar)
- Make sure `python-dotenv` is installed: `pip install python-dotenv`

## Additional Notes

- The `.env.local` file should be in `.gitignore` to avoid committing secrets
- Never commit API keys to version control
- If using a team, use secure secret management tools
- Consider using environment-specific files (`.env.development`, `.env.production`)

## Testing the Connection

After fixing, you should see:
- No 401 errors in the logs
- Successful WebSocket connection to `wss://api.openai.com/v1/realtime`
- The agent should be able to process voice input/output

If problems persist, check the OpenAI status page: https://status.openai.com/
