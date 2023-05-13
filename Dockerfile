# vim:set ft=dockerfile:
FROM docker.io/golang:1.19 as gobuilder
RUN GO111MODULE=on go install golang.stackrox.io/kube-linter/cmd/kube-linter@latest
FROM docker.io/node:16-bullseye-slim as target
ARG CS_VERSION=4.11.0
ARG DEB_PACKAGES="vim git jq man locales curl netcat-openbsd traceroute bind9-dnsutils file iputils-ping openssh-client make bash-completion dialog libcap2-bin podman python3-pip python3-venv python3-ldap unzip ldap-utils build-essential pkg-config python3 dumb-init sudo libffi-dev libssl-dev libsecret-1-0"
ARG ANSIBLE_COLLECTIONS="kubernetes.core community.crypto community.general"
ARG PYTHON_PACKAGES="jmespath jsonpatch kubernetes>=12.0.0 ansible-lint yamllint molecule pylint netaddr"
ARG NODE_PACKAGES="serverless parcel code-server@${CS_VERSION}"
ARG KUBECTL_VERSION=v1.25.7
ARG BK_VERSION=v0.1.6
ARG IMG_VERSION=v0.5.11
ARG HELM_VERSION=v3.10.3
ARG HADOLINT_VERSION=v2.12.0
ARG ANSIBLE_VERSION=7.1.0
ARG FAASCLI_VERSION=0.15.2
ARG VIRTCTL_VERSION=v0.58.0
ARG TF_VERSION=1.3.6
ARG YQ_VERSION=v4.30.5
ARG TASK_VERSION=v3.18.0
ARG FISSION_VERSION=v1.18.0
ARG ARGO_VERSION=v3.4.5
ARG TILT_VERSION=0.30.13
ARG SHELLCHECK_VERSION=v0.9.0
ARG RESTIC_VERSION=0.15.1
USER root
COPY profile/*.sh /etc/profile.d/
COPY entrypoint.sh /usr/local/bin/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3003,DL3008,DL3013,DL3015,DL3016,SC2035
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install ${DEB_PACKAGES} \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && SUFFIX="";case "$(uname -m)" in arm) SUFFIX="-armhf";ARCHITECTURE=arm;ARCH=arm;SA=armv6hf;; armv8*|aarch64*) SUFFIX="-arm64";ARCHITECTURE=arm64;ARCH=arm64;SA=aarch64;; x86_64|i686|*) ARCHITECTURE=amd64;ARCH=x86_64;SA="$ARCH";; esac \
 && curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.5.1/fixuid-0.5.1-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - \
 && curl -sL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl" -o /usr/local/bin/kubectl \
 && echo "$(curl -sL "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl.sha256") /usr/local/bin/kubectl" | sha256sum --check \
 && curl -sL "https://github.com/vmware-tanzu/buildkit-cli-for-kubectl/releases/download/${BK_VERSION}/linux-${BK_VERSION}.tgz"| tar -C /usr/local/bin/ -xzf - \
 && curl -sL "https://github.com/genuinetools/img/releases/download/${IMG_VERSION}/img-linux-${ARCHITECTURE}" -o "/usr/local/bin/img" \
 && curl -sL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCHITECTURE}.tar.gz" |tar --wildcards -C /usr/local/bin/ --strip-components=1 -xzf - */helm \
 && curl -sL "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-${ARCH}" -o "/usr/local/bin/hadolint" \
 && curl -sL "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.${SA}.tar.xz" | tar --wildcards -C /usr/local/bin/ --strip-components=1 -xJf - */shellcheck \
 && curl -sL "https://github.com/openfaas/faas-cli/releases/download/${FAASCLI_VERSION}/faas-cli${SUFFIX}" -o "/usr/local/bin/faas-cli" \
 && curl -sL "https://github.com/fission/fission/releases/download/${FISSION_VERSION}/fission-${FISSION_VERSION}-linux-${ARCHITECTURE}" -o "/usr/local/bin/fission" \
 && curl -sL "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${ARCHITECTURE}.bz2" | bzip2 -cd >/usr/local/bin/restic \
 && curl -sL "https://github.com/argoproj/argo-workflows/releases/download/${ARGO_VERSION}/argo-linux-${ARCHITECTURE}.gz" | gzip -cd > /usr/local/bin/argo \
 && curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCHITECTURE}" -o "/usr/local/bin/yq" \
 && curl -sL "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_linux_${ARCHITECTURE}.tar.gz"| tar -C /usr/local/bin/ -xzf - task \
 && curl -sL "https://github.com/tilt-dev/tilt/releases/download/v${TILT_VERSION}/tilt.${TILT_VERSION}.linux.${ARCH}.tar.gz"| tar -C /usr/local/bin/ -xzf - tilt \
 && curl -sL "https://github.com/kubevirt/kubevirt/releases/download/${VIRTCTL_VERSION}/virtctl-${VIRTCTL_VERSION}-linux-amd64" -o "/usr/local/bin/kubectl-virt" \
 && curl -sL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCHITECTURE}.zip" -o /tmp/tf.zip \
 && unzip /tmp/tf.zip terraform -d /usr/local/bin \
 && rm /tmp/tf.zip \
 && pip install --no-cache-dir -U pip \
 && pip install --no-cache-dir ansible==${ANSIBLE_VERSION} ${PYTHON_PACKAGES} \
 && ansible-galaxy collection install ${ANSIBLE_COLLECTIONS} \
 && chmod 0755 /usr/local/bin/* \
 && chown root:root /usr/local/bin/fixuid \
 && chmod 4755 /usr/local/bin/fixuid \
 && mkdir -p /etc/fixuid \
 && sed -i 's/node/coder/g' /etc/passwd /etc/group /etc/shadow \
 && printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml \
 && echo "coder ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/coder \
 && chmod 0600 /etc/sudoers.d/coder \
 && npm config set python python3 \
 && npm install --global ${NODE_PACKAGES} --unsafe-perm \
 && mkdir -p /home/coder/projects /usr/local/startup \
 && cd /usr/local/lib/node_modules/code-server/lib/vscode && npm install --legacy-peer-deps . \
 && chown -R coder:coder /home/coder \
 && /bin/echo -e 'unqualified-search-registries=["docker.io", "quai.io"]\n[[registry]]\nlocation = "registry:80"\ninsecure = true\n'>/etc/containers/registries.conf \
 && /bin/echo -e '[containers]\nnetns="host"\nuserns="host"\nipcns="host"\nutsns="host"\ncgroupns="host"\nclog_driver = "k8s-file"\ncgroups = "disabled"\n[engine]\ncgroup_manager = "cgroupfs"\nevents_logger="file"\n'>/etc/containers/containers.conf \
 && /bin/echo -e '[storage]\ndriver = "overlay"\nrunroot = "/run/containers/storage"\ngraphroot = "/var/lib/containers/storage"\n[storage.options]\npull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}\n[storage.options.overlay]\nmount_program = "/usr/bin/fuse-overlayfs"\nmountopt = "nodev,fsync=0"\n'>/etc/containers/storage.conf \
 && setcap cap_setuid+eip /usr/bin/newuidmap \
 && setcap cap_setgid+eip /usr/bin/newgidmap \
 && chmod 0755 /usr/bin/new?idmap \
 && /bin/echo -e 'coder:1:999\ncoder:1001:64535\n' >/etc/subuid \
 && /bin/echo -e 'coder:1:999\ncoder:1001:64535\n' >/etc/subgid \
 && echo "source /etc/profile">>/etc/skel/.bashrc \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen
COPY --from=gobuilder /go/bin/kube-linter /usr/local/bin
USER coder:coder
WORKDIR /home/coder
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
