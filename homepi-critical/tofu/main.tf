terraform {
  required_providers {
    technitium = {
      source = "registry.terraform.io/kenske/technitium"
    }
  }
}

# Using API username/password
provider "technitium" {
  host     = "http://technitium:5380"
  token    = var.HPI_TECHNITIUM_TOKEN
}

resource "technitium_dns_zone" "home" {
  name                       = var.HPI_DNS_DOMAIN
  type                       = "Primary"
  use_soa_serial_date_scheme = true
}

resource "technitium_dns_zone_record" "wildcard" {
  domain     = "*.${var.HPI_DNS_DOMAIN}"
  type       = "A"
  ip_address = var.HPI_LOCAL_IP_ADDRESS
  ttl        = "3600"

  depends_on = [technitium_dns_zone.home]
}