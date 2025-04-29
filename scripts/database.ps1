param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$MongoUri,
    
    [Parameter(Mandatory=$false)]
    [switch]$Backup,
    
    [Parameter(Mandatory=$false)]
    [switch]$Restore,
    
    [Parameter(Mandatory=$false)]
    [switch]$Migrate,
    
    [Parameter(Mandatory=$false)]
    [switch]$Seed,
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "./backups"
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if MongoDB tools are installed
$mongodumpStatus = mongodump --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "MongoDB tools are not installed. Please install them and try again."
    exit 1
}

# Create backup directory if it doesn't exist
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath
    Write-Host "Created backup directory: $BackupPath"
}

# Function to create backup
function Backup-Database {
    param(
        [string]$Uri,
        [string]$Path
    )
    
    Write-Host "Creating database backup..."
    
    # Get current timestamp
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupDir = "$Path/$Environment-$timestamp"
    
    # Create backup
    mongodump --uri $Uri --out $backupDir
    
    if ($LASTEXITCODE -eq 0) {
        # Compress backup
        Compress-Archive -Path $backupDir -DestinationPath "$backupDir.zip"
        Remove-Item -Path $backupDir -Recurse -Force
        
        Write-Host "Backup completed successfully!"
        Write-Host "Backup file: $backupDir.zip"
    } else {
        Write-Host "Backup failed!"
        exit 1
    }
}

# Function to restore database
function Restore-Database {
    param(
        [string]$Uri,
        [string]$Path
    )
    
    Write-Host "Restoring database..."
    
    # Get latest backup
    $latestBackup = Get-ChildItem -Path $Path -Filter "$Environment-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if (-not $latestBackup) {
        Write-Host "No backup found for environment: $Environment"
        exit 1
    }
    
    # Extract backup
    $extractPath = "$Path/temp"
    if (Test-Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }
    Expand-Archive -Path $latestBackup.FullName -DestinationPath $extractPath
    
    # Restore backup
    mongorestore --uri $Uri --dir $extractPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Restore completed successfully!"
    } else {
        Write-Host "Restore failed!"
        exit 1
    }
    
    # Clean up
    Remove-Item -Path $extractPath -Recurse -Force
}

# Function to run migrations
function Run-Migrations {
    param(
        [string]$Uri
    )
    
    Write-Host "Running database migrations..."
    
    # Create migrations directory if it doesn't exist
    $migrationsPath = "./migrations"
    if (-not (Test-Path $migrationsPath)) {
        New-Item -ItemType Directory -Path $migrationsPath
        Write-Host "Created migrations directory"
    }
    
    # Get current timestamp
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $migrationFile = "$migrationsPath/$timestamp-migration.js"
    
    # Create migration file
    @"
// Migration: $timestamp
// Environment: $Environment

db = db.getSiblingDB('chat');

// Add indexes
db.users.createIndex({ name: 'text' });
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ googleId: 1 }, { unique: true });

db.chats.createIndex({ participants: 1 });
db.chats.createIndex({ 'messages.sender': 1 });
db.chats.createIndex({ 'messages.createdAt': 1 });

// Add validation
db.runCommand({
  collMod: 'users',
  validator: {
    \$jsonSchema: {
      bsonType: 'object',
      required: ['googleId', 'email', 'name', 'picture'],
      properties: {
        googleId: { bsonType: 'string' },
        email: { bsonType: 'string' },
        name: { bsonType: 'string' },
        picture: { bsonType: 'string' },
        status: { 
          bsonType: 'string',
          enum: ['online', 'offline']
        },
        lastSeen: { bsonType: 'date' }
      }
    }
  }
});

db.runCommand({
  collMod: 'chats',
  validator: {
    \$jsonSchema: {
      bsonType: 'object',
      required: ['participants', 'createdBy'],
      properties: {
        name: { bsonType: 'string' },
        isGroup: { bsonType: 'bool' },
        participants: { 
          bsonType: 'array',
          items: { bsonType: 'objectId' }
        },
        messages: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            required: ['sender', 'content'],
            properties: {
              sender: { bsonType: 'objectId' },
              content: { bsonType: 'string' },
              readBy: {
                bsonType: 'array',
                items: { bsonType: 'objectId' }
              },
              createdAt: { bsonType: 'date' }
            }
          }
        },
        createdBy: { bsonType: 'objectId' }
      }
    }
  }
});
"@ | Out-File -FilePath $migrationFile -Encoding UTF8
    
    # Apply migration
    mongosh $Uri $migrationFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Migration completed successfully!"
    } else {
        Write-Host "Migration failed!"
        exit 1
    }
}

# Function to seed database
function Seed-Database {
    param(
        [string]$Uri
    )
    
    Write-Host "Seeding database..."
    
    # Create seed data
    $seedFile = "./migrations/seed.js"
    
    @"
// Seed data
// Environment: $Environment

db = db.getSiblingDB('chat');

// Create test users
db.users.insertMany([
  {
    googleId: 'test-user-1',
    email: 'test1@example.com',
    name: 'Test User 1',
    picture: 'https://example.com/avatar1.jpg',
    status: 'offline',
    lastSeen: new Date()
  },
  {
    googleId: 'test-user-2',
    email: 'test2@example.com',
    name: 'Test User 2',
    picture: 'https://example.com/avatar2.jpg',
    status: 'offline',
    lastSeen: new Date()
  }
]);

// Create test chat
db.chats.insertOne({
  name: 'Test Chat',
  isGroup: false,
  participants: [
    ObjectId(db.users.findOne({ email: 'test1@example.com' })._id),
    ObjectId(db.users.findOne({ email: 'test2@example.com' })._id)
  ],
  messages: [
    {
      sender: ObjectId(db.users.findOne({ email: 'test1@example.com' })._id),
      content: 'Hello!',
      readBy: [
        ObjectId(db.users.findOne({ email: 'test1@example.com' })._id)
      ],
      createdAt: new Date()
    }
  ],
  createdBy: ObjectId(db.users.findOne({ email: 'test1@example.com' })._id)
});
"@ | Out-File -FilePath $seedFile -Encoding UTF8
    
    # Apply seed data
    mongosh $Uri $seedFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Seeding completed successfully!"
    } else {
        Write-Host "Seeding failed!"
        exit 1
    }
}

# Function to clean database
function Clean-Database {
    param(
        [string]$Uri
    )
    
    Write-Host "Cleaning database..."
    
    # Drop collections
    mongosh $Uri --eval "db = db.getSiblingDB('chat'); db.users.drop(); db.chats.drop();"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database cleaned successfully!"
    } else {
        Write-Host "Database cleaning failed!"
        exit 1
    }
}

# Execute requested operations
if ($Backup) {
    Backup-Database -Uri $MongoUri -Path $BackupPath
}

if ($Restore) {
    Restore-Database -Uri $MongoUri -Path $BackupPath
}

if ($Migrate) {
    Run-Migrations -Uri $MongoUri
}

if ($Seed) {
    Seed-Database -Uri $MongoUri
}

if ($Clean) {
    Clean-Database -Uri $MongoUri
}

Write-Host "`nDatabase management completed!" 