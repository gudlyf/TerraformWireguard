# TerraformWireguard

Simple Terraform for setting up a Linux-based Wireguard server in the cloud. Currently only setup for AWS, but I can create GCP and Azure for anyone really wanted it, upon request.

Note that the server is created in the Canada region by default and can be easily changed as needed. Also, DNS is not handled by the Wireguard server, so it's configured with 1.1.1.1 and 9.9.9.9 and might *possibly* mean DNS exfiltration, if you're concerned at all about that.

Proven to work with Wireguard v1.0.20210606 (Linux), v0.5.2 (Windows), and v1.0.15 (iOS).

NOTES:

- Be sure to create the required private/public SSH keys and place them where Terraform can read them (i.e., `ssh keygen`)
- Creates a single client configuration file that is then downloaded to the system issuing the Terraform apply
- The Terraform state files are stored on your local system. It's up to you to configure `main.tf` to store elsewhere, if you want
