FROM alpine:latest

RUN apk add --no-cache \
    bash \
    perl \
    libc6-compat

RUN wget https://github.com/Benson-Genomics-Lab/TRF/releases/download/v4.09.1/trf409.linux64 -O trf409.legacylinux64 && \
    chmod +x trf409.legacylinux64 && \
    mv trf409.legacylinux64 /usr/local/bin/trf


#ENTRYPOINT ["/usr/local/bin/trf"]
