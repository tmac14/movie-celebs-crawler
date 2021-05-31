FROM nginx:latest

ARG HOST_UID
ARG HOST_GID

ADD nginx.conf /etc/nginx/conf.d/default.conf
ADD php-upstream.conf /etc/nginx/conf.d/upstream.conf

RUN apt-get update && apt-get install -y curl
RUN cd /etc/nginx/conf.d/ \
    && rm -rf /var/lib/apt/lists/*

RUN usermod -u ${HOST_UID} www-data
