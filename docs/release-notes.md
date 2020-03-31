# RELEASE NOTES

## xx

### Added letsencrypt_disabled switch

This allows you to disable letsencrypt setup. (Default is enabled letsencrypt.)

### Update air-gapped docs 

Add `REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true` to air-gapped registry. That solve some skopeo copy problemes.

## 24.3.2020

### Support for disabling automatic Let's Encrypt certificates for apps and api

Add varialbe `letsencrypt_disabled: true` to cluster yaml to disable Let's Encrypt certificates. Variable defaults to true.

### Added release notes doc

Just simple doc to track new features and fixes.


