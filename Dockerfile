# Build Hugo's pub files on Debian:latest
FROM ubuntu:20.04 as HUGO

RUN apt-get update -y
RUN apt-get install hugo -y

COPY ./sources /static-site

RUN hugo -v --source=/static-site --destination=/static-site/public
RUN VERSION=$(cat version);sed -i "s/2019-01-15/v.$VERSION/g" /static-site/public/about/index.html

# Serve the public files using nginx:alpine
FROM nginx:stable-alpine
RUN mv /usr/share/nginx/html/index.html /usr/share/nginx/html/old-index.html
COPY --from=HUGO /static-site/public/ /usr/share/nginx/html/

# Instruct the container to listen for requests on port 80 (HTTP).
EXPOSE 80
