FROM node:20-alpine AS base
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source
COPY src/ ./src/

# Expose port
EXPOSE 8080

# Start Node.js server
CMD ["node", "--experimental-vm-modules", "src/index.js"]
