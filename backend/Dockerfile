# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Development stage
FROM node:18-alpine as development

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies including development dependencies
RUN npm install && \
    npm install -g ts-node-dev

# Copy source code
COPY . .

# Expose port
EXPOSE 5000

# Start development server
CMD ["ts-node-dev", "--respawn", "--transpile-only", "src/index.ts"]

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy built assets from build stage
COPY --from=build /app/dist ./dist

# Create volume for logs
VOLUME ["/app/logs"]

# Expose port
EXPOSE 5000

# Start server
CMD ["npm", "start"]
 