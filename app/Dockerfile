FROM nginx:1.25-alpine

# Copy custom nginx config if needed
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
