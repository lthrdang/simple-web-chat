param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$MongoUri
)

# Validate environment
if ($Environment -notin @("dev", "staging", "prod")) {
    Write-Host "Invalid environment. Must be one of: dev, staging, prod"
    exit 1
}

# Check if mongosh is installed
$mongoshStatus = mongosh --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "MongoDB Shell is not installed. Please install it and try again."
    exit 1
}

# Create migrations directory if it doesn't exist
if (-not (Test-Path ./migrations)) {
    New-Item -ItemType Directory -Path ./migrations
    Write-Host "Created migrations directory"
}

# Get current timestamp
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Create migration file
$migrationFile = "./migrations/$timestamp-migration.js"
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

Write-Host "Created migration file: $migrationFile"

# Apply migration
Write-Host "Applying migration..."
mongosh $MongoUri $migrationFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Migration completed successfully!"
} else {
    Write-Host "Migration failed!"
    exit 1
} 