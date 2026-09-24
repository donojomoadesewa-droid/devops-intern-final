FROM nginx:1.27.5-alpine3.21-slim

ARG BUILD_SHA=unknown

COPY index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN sed -i "s/{{BUILD_SHA}}/${BUILD_SHA}/g"  /usr/share/nginx/html/index.html

RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser && \
    chown   -R appuser:appgroup /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    touch   /var/run/nginx.pid && \
    chown   appuser:appgroup /var/run/nginx.pid

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s CMD wget -q --spider http://localhost:8080/healthz || exit 1

CMD ["nginx", "-g" , "daemon off;"]
     
