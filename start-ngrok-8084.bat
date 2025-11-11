@echo off
REM Start ngrok tunnel for OAuth MCP Server on port 8084

echo ======================================================================
echo            Starting ngrok Tunnel for OAuth MCP Server
echo ======================================================================
echo.

echo Stopping existing ngrok processes...
taskkill /F /IM ngrok.exe >nul 2>&1

echo Waiting for endpoint to release (10 seconds)...
timeout /t 10 /nobreak >nul

echo Starting ngrok tunnel on port 8084...
echo.
echo ======================================================================
echo   ngrok will start in a new window
echo   Check the ngrok window for the public URL
echo ======================================================================
echo.
echo OAuth Credentials:
echo   Client ID:     fba72649dc07cf7824aa578f6f75ffc7
echo   Client Secret: 7ea51b30220a71ea117316631d4bcd49277d50ed1b2e6db2372c856d0a7d12bb
echo.
echo OAuth Endpoints (replace {NGROK_URL} with the URL from ngrok window):
echo   Authorization:  {NGROK_URL}/authorize
echo   Token:          {NGROK_URL}/oauth/token
echo   Discovery:      {NGROK_URL}/.well-known/oauth-authorization-server
echo.
echo ======================================================================
echo.

start ngrok http 8084
