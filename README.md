[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit) [![pre-commit.ci status](https://results.pre-commit.ci/badge/github/brucellino/packer-templates/main.svg)](https://results.pre-commit.ci/latest/github/brucellino/packer-templates/main) [![semantic-release: angular](https://img.shields.io/badge/semantic--release-conventional-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

# Packer templates

_Packer templates for fun and profit._

These are the packer templates that I've worked on in the past and found useful.
YMMV.

## Templates

Templates typically build docker images, but in some cases also cloud images for _e.g._ AWS, Digital Ocean, _etc_.

### Secrets

Secrets are required, as the case may be, in order to pull or push images from registry.
I use a [Hashicorp Vault](https://vaultproject.io) instance to store these credentials, but you won't have access to that.
Before using this repo for your own nefarious ends, make sure to replace `local` lookups in the templates and pass your own credentials.

## Images

Every attempt is made to actually push images defined in templates.
The deciding factor is that the storage of these images should be zero-cost, so only free registries are used.
