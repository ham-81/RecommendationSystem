$ErrorActionPreference = "Stop"

$root = "d:\Project\Reel Recommendation"
$python = "$root\.venv\Scripts\python.exe"
$dbDir = "$root\database"
$mlDir = "$root\ml model"
$flutterDir = "$root\flutter\reel_recommandation"

Write-Host "Starting DB API..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$dbDir'; & '$python' app.py"

Write-Host "Starting ML pipeline..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$mlDir'; & '$python' run_pipeline.py"

Write-Host "Starting Flutter app..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$flutterDir'; flutter run -d windows"

Write-Host "All launch commands sent. Check each opened terminal window for status."
