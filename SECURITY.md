# Security

This is a private repository. Treat source code, app ideas, animation assets,
signing material, and credentials as private by default.

## Do Not Commit

- API keys
- Tokens
- Passwords
- Signing certificates
- Provisioning profiles
- Private Apple account material
- Vendor assets that cannot be redistributed

## If A Secret Is Committed

1. Revoke or rotate the secret first.
2. Remove it from the repo.
3. If necessary, rewrite history only after confirming the impact.

Deleting a secret from the latest commit is not enough if the value was already
pushed. Assume pushed secrets are compromised.
