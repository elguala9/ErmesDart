# Publish the NAT-test image

## Setup (once)

Set the Quay.io robot-account secrets on GitHub:

```bash
gh secret set QUAY_USERNAME --body "elguala9+ci"
gh secret set QUAY_TOKEN --body "your_robot_token"
```

Commit the publish workflow + script so the trigger lives in your commit:

```bash
git add .github/workflows/docker-publish-nat.yml scripts/publish_nat.dart .gitignore
git commit -m "feat(nat): one-command publish via dedicated branch"
```

## Publish (every time)

```bash
melos run publish:nat
# or, equivalently:
dart run scripts/publish_nat.dart
```

Pushes your current commit to the `publish-nat-image` branch → GitHub Actions
builds and pushes `quay.io/elguala9/ermes-nat-test:latest` (+ `:<sha>`) to
Quay.io. Does not touch your working tree or current branch.

The git remote is auto-detected (the upstream of your current branch, else the
only remote, else `origin`). If you have several remotes and no upstream set,
pass it explicitly: `dart run scripts/publish_nat.dart <remote>`.

```bash
gh run watch        # follow the build (optional)
```

Token: quay.io → elguala9 → Robot Accounts (write access to the
`elguala9/ermes-nat-test` repository).
