# Quick Start Script for Windows PowerShell
# Run this to install dependencies and verify setup

Write-Host "🚀 Granny AI Voice Agent - Quick Start" -ForegroundColor Green
Write-Host ""

# Check if uv is installed
Write-Host "Checking for uv package manager..." -ForegroundColor Cyan
try {
    $uvVersion = uv --version
    Write-Host "✅ uv is installed: $uvVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ uv is not installed" -ForegroundColor Red
    Write-Host "Installing uv..." -ForegroundColor Yellow
    irm https://astral.sh/uv/install.ps1 | iex
}

Write-Host ""
Write-Host "📦 Installing dependencies..." -ForegroundColor Cyan
uv sync

Write-Host ""
Write-Host "🔍 Checking environment variables..." -ForegroundColor Cyan

$envFile = ".env.local"
if (Test-Path $envFile) {
    $content = Get-Content $envFile -Raw
    
    $checks = @{
        "LIVEKIT_API_KEY" = $content -match 'LIVEKIT_API_KEY="[^"]+"'
        "LIVEKIT_API_SECRET" = $content -match 'LIVEKIT_API_SECRET="[^"]+"'
        "LIVEKIT_URL" = $content -match 'LIVEKIT_URL="[^"]+"'
        "OPENAI_API_KEY" = $content -match 'OPENAI_API_KEY="[^"]+"'
        "DEEPGRAM_API_KEY" = $content -match 'DEEPGRAM_API_KEY="[^"]+"' -and $content -notmatch 'DEEPGRAM_API_KEY="your_deepgram_api_key_here"'
        "ELEVENLABS_API_KEY" = $content -match 'ELEVENLABS_API_KEY="[^"]+"' -and $content -notmatch 'ELEVENLABS_API_KEY="your_elevenlabs_api_key_here"'
    }
    
    foreach ($key in $checks.Keys) {
        if ($checks[$key]) {
            Write-Host "  ✅ $key is set" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $key is missing or placeholder" -ForegroundColor Red
        }
    }
    
    if (-not $checks["DEEPGRAM_API_KEY"]) {
        Write-Host ""
        Write-Host "⚠️  Get Deepgram API key at: https://console.deepgram.com/" -ForegroundColor Yellow
    }
    
    if (-not $checks["ELEVENLABS_API_KEY"]) {
        Write-Host "⚠️  Get ElevenLabs API key at: https://elevenlabs.io/" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ .env.local file not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "✨ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Add your Deepgram and ElevenLabs API keys to .env.local"
Write-Host "2. Run the agent: uv run agent.py dev"
Write-Host "3. Run the server: uv run server.py"
Write-Host "4. Launch your Flutter app"
Write-Host ""
Write-Host "📚 See README.md for full documentation" -ForegroundColor Cyan
