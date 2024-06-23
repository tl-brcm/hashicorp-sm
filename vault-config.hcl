listener "tcp" {
  address       = "0.0.0.0:8300"
  tls_cert_file = "./server_key_pairs/vault_certificate.pem"
  tls_key_file  = "./server_key_pairs/vault_private_key.pem"
}

storage "inmem" {}

ui = true

