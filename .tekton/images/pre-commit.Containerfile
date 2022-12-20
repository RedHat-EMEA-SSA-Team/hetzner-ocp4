FROM registry.access.redhat.com/ubi9/python-39:latest

RUN pip install pre-commit

WORKDIR /workdir
CMD pre-commit run --all-files
