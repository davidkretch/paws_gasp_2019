FROM amazonlinux:latest
RUN yum -y install which unzip aws-cli
RUN amazon-linux-extras install R3.4
ADD fetch_and_run.sh /usr/local/bin/fetch_and_run.sh
WORKDIR /tmp
USER nobody
ENTRYPOINT ["/usr/local/bin/fetch_and_run.sh"]
