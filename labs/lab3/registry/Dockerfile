FROM registry.access.redhat.com/ubi8
LABEL maintainer="student@example.com"

RUN yum -y install docker-registry && \
      yum clean all

EXPOSE 5000

ENTRYPOINT ["/usr/bin/registry"]

CMD ["serve", "/etc/docker-distribution/registry/config.yml"]
