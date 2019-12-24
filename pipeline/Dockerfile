FROM registry.access.redhat.com/ubi7/ubi

LABEL maintainer="Robert Bohne"

ENV HOME=/workspace/

RUN yum update -y && rm -rf /var/cache/yum
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum -y install git ansible nss_wrapper gettext \
    && yum clean all
RUN mkdir /workspace && chmod g+w /workspace
RUN mkdir /container-scripts && chmod g+w /container-scripts

ADD container-scripts/* /container-scripts/

ENTRYPOINT ["/container-scripts/entrypoint.sh"]