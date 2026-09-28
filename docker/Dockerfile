FROM debian:bookworm-slim

WORKDIR /blink

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*


COPY tools/arm_gcc/ /opt/arm_gcc/

ENV PATH="/opt/arm_gcc/bin:${PATH}"

COPY . .

RUN cmake --preset default

CMD ["cmake", "--build","--preset", "default"]



