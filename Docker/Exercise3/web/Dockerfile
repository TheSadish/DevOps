FROM tomcat:10-jdk21

LABEL "Project"="VProfile"
LABEL "Author"="Sadish"

RUN rm -rf /etc/nginx/conf.d/default.conf
COPY nginvproapp.conf /etc/nginx/conf.d/vproapp.conf