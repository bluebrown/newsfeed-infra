resource "helm_release" "nginx_ingress" {
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.0.13"
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  atomic           = true

  set {
    name  = "controller.service.enabled"
    value = "true"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.allowSnippetAnnotations"
    value = "false"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

}

data "kubernetes_service" "nginx_controller_svc" {
  depends_on = [helm_release.nginx_ingress]
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

output "load_balancer_dns" {
  value = data.kubernetes_service.nginx_controller_svc.status[0].load_balancer[0].ingress[0].hostname
}
