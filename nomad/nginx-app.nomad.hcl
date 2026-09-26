job "nginx-app" {
  datacenters = ["dc1"]

  group "web" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx-app:latest"

        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "nginx-app"
        port = "http"

        check {
          type     = "http"
          path     = "/healthz"
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}