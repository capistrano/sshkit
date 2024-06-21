FROM ubuntu:22.04
WORKDIR /provision
COPY ./ubuntu_setup.sh ./
RUN ./ubuntu_setup.sh
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
