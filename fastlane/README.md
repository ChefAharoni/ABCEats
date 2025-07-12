# Fastlane Setup for ABCEats

This directory contains Fastlane configuration for automated iOS code signing and CI/CD builds.

## Prerequisites

- Ruby (recommended via rbenv or system Ruby)
- Fastlane (`sudo gem install fastlane -NV`)
- A private Git repo for match (for storing signing credentials)

## Setup Steps

1. **Edit `Appfile`**

   - Set your `app_identifier` (bundle ID)
   - Set your `apple_id` (Apple Developer account email)
   - (Optional) Set your `team_id` if you have multiple teams

2. **Set Up Match**

   - Run `fastlane match init` and follow the prompts
   - Store your match repo URL securely

3. **Set Environment Variables in CI**

   - `MATCH_PASSWORD` — encryption password for match repo
   - `MATCH_GIT_URL` — your private match repo URL
   - (Optional) `APP_IDENTIFIER`, `DEVELOPER_APP_ID`, `TEAM_ID`

4. **Configure Your CI/CD Pipeline**
   - Add a step to run:
     ```sh
     fastlane ci_build
     ```

## What the `ci_build` Lane Does

- Fetches and installs signing credentials using `match`
- Builds and signs the app using the `ABCEats` scheme
- Uses the `development` export method (change to `app-store` or `ad-hoc` as needed)

## Security

- Signing credentials are encrypted in your match repo
- Only CI and trusted developers should have access

## Resources

- [Fastlane Docs](https://docs.fastlane.tools/)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/)

## Example CI/CD Step (GitHub Actions)

```yaml
- name: Build and sign iOS app
  run: fastlane ci_build
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
    # Add other secrets as needed
```
