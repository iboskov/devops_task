FROM nginx:1.25-alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config template
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Copy static files
COPY index.html /usr/share/nginx/html/

# Environment variables for backend connection
ENV BACKEND_HOST=backend
ENV BACKEND_PORT=5000

EXPOSE 80

# nginx will substitute environment variables in the template
CMD ["nginx", "-g", "daemon off;"]
