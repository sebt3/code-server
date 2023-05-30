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

k.secret() {
    case "$#" in
        0) kubectl get secrets -A|awk '$3=="Opaque"';;
        1) kubectl get secrets -n $1|awk '$2=="Opaque"';;
        2) kubectl get secrets -n $1 $2 -o jsonpath='{.data}'|jq .;;
        3) kubectl get secrets -n $1 $2 -o jsonpath="{.data.$3}"|base64 -d;echo;;
        *) echo invalid number of args
     esac
}

k.ing() {
    kubectl get ing,ingressroute -o custom-columns="KIND":.kind,"NS":.metadata.namespace,"NAME":.metadata.name,"HOSTS":.spec.rules[*].host,"MATCH":.spec.routes[*].match "$@"
}

k.img() {
    kubectl get pod -o custom-columns="NS":.metadata.namespace,"NAME":.metadata.name,"CONTAINER-IMAGES":.spec.containers[*].image "$@"
}
