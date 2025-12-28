FROM nginx:1.25-alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY index.html /usr/share/nginx/html/
ENV BACKEND_HOST=backend
ENV BACKEND_PORT=5000

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
