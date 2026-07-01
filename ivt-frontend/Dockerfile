# mRNA Digital Twin — frontend image (React build served by nginx).
#
# The app makes requests to http://127.0.0.1:8000 from the user's BROWSER, so as
# long as the backend container publishes port 8000 on the host (see
# docker-compose.yml), those requests resolve correctly. No code change needed.

# ---- build stage ------------------------------------------------------------
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
RUN npm run build

# ---- serve stage ------------------------------------------------------------
FROM nginx:1.27-alpine
# SPA routing: fall back to index.html for client-side routes
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
