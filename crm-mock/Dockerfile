# Lightweight Node.js image for the mock CRM service
FROM node:20-alpine

WORKDIR /usr/src/app

# Install only production dependencies
COPY package*.json ./
RUN npm install --only=production

# Copy application source
COPY server.js ./

EXPOSE 8080

CMD ["npm", "start"]
