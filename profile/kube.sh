fnct_kube() {
    source <(helm completion bash)
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
    alias k=kubectl
    alias code=code-server
    export EDITOR=vim
}
fnct_kube
unset fnct_kube

k.ns() {
    local ns=$1

    if [ $# -gt 0 ];then
        kubectl config set-context --current --namespace=$ns
    else
        kubectl get ns
    fi
}
__comp_k_ns() {
    local latest="${COMP_WORDS[$COMP_CWORD]}"
    COMPREPLY=($(compgen -W "$(kubectl get ns -o name|sed 's#^namespace/##')" -- $latest))
}
complete -F __comp_k_ns k.ns

k.ctx() {
    local ctx=$1

    if [ $# -gt 0 ];then
        kubectl config use-context $ctx
    else
        kubectl config get-contexts -o name
    fi
}
__comp_k_ctx() {
    local latest="${COMP_WORDS[$COMP_CWORD]}"
    COMPREPLY=($(compgen -W "$(kubectl config get-contexts -o name)" -- $latest))
}
complete -F __comp_k_ctx k.ctx

k.secret() {
    case "$#" in
        0) kubectl get secrets -A|awk '$3=="Opaque"';;
        1) kubectl get secrets -n $1|awk '$2=="Opaque"';;
        2) kubectl get secrets -n $1 $2 -o jsonpath='{.data}'|jq .;;
        3) kubectl get secrets -n $1 $2 -o jsonpath="{.data.$3}"|base64 -d;echo;;
        *) echo invalid number of args
     esac
}
__comp_k_secret() {
    local latest="${COMP_WORDS[$COMP_CWORD]}"
    case "$COMP_CWORD" in
    1)  COMPREPLY=($(compgen -W "$(kubectl get ns -o name|sed 's#^namespace/##')" -- $latest));;
    2)  local NS=${COMP_WORDS[1]};COMPREPLY=($(compgen -W "$(kubectl get secrets -n "$NS" |awk '$2=="Opaque"{print $1}')" -- $latest));;
    3)  local NS=${COMP_WORDS[1]};local SEC=${COMP_WORDS[2]};COMPREPLY=($(compgen -W "$(kubectl get secrets -n $NS $SEC -o 'jsonpath={.data}'|jq -r '. |keys[]')" -- $latest));;
    esac
}
complete -F __comp_k_secret k.secret

k.fin () { kubectl patch "$@" -p '{"metadata":{"finalizers":null}}' --type=merge; }
k.ing() {
    kubectl get ing,ingressroute -o custom-columns="KIND":.kind,"NS":.metadata.namespace,"NAME":.metadata.name,"HOSTS":.spec.rules[*].host,"MATCH":.spec.routes[*].match "$@"
}

k.img() {
    kubectl get pod -o custom-columns="NS":.metadata.namespace,"NAME":.metadata.name,"CONTAINER-IMAGES":.spec.containers[*].image "$@"
}
