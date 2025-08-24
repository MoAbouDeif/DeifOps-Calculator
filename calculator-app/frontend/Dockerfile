# Use a specific Node.js LTS version for stability and security
FROM node:20-alpine3.22 AS builder

# Set build-time environment variable for API base URL
ARG REACT_APP_API_BASE_URL=/api
ENV REACT_APP_API_BASE_URL=$REACT_APP_API_BASE_URL

WORKDIR /app

# Install only production dependencies for faster builds
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the React app
RUN npm run build

# Use a minimal, stable Nginx image
FROM nginx:stable-alpine3.21-slim

# Remove default Nginx config for clarity
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx config and built app
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s CMD wget -q --spider http://localhost || exit 1

CMD ["nginx", "-g", "daemon off;"]
