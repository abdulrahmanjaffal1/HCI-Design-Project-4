FROM swift:6.4.2-jammy
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl libfuse2 libimobiledevice-utils && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/xtool
RUN set -eu; case "$(uname -m)" in \
      x86_64) hash=dbfd9d7216f077c84c171b688c4173c37c23ca76bf7fd185d1a9ae8a53dab59f ;; \
      aarch64) hash=4bc0515fed71efb86e82564f358efa0c4c6d76bf1bcfd4c5f256727b53ec59c8 ;; \
      *) exit 1 ;; esac; \
    curl -fLsS "https://github.com/xtool-org/xtool/releases/download/1.24.0/xtool-$(uname -m).AppImage" -o image; \
    echo "$hash  image" | sha256sum -c -; chmod +x image; ./image --appimage-extract >/dev/null; rm image; \
    printf '#!/bin/sh\nexec /opt/xtool/squashfs-root/AppRun "$@"\n' > /usr/local/bin/xtool; chmod +x /usr/local/bin/xtool
WORKDIR /project
CMD ["bash"]
