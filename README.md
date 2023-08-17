# Centralized nightly CI builds for TileDB conda feedstocks

| Name      | status                                                                                                                                                                                                   | azure                                                                                                                                                                                                                            | version                                                                                                       | last updated                                                                          | downloads                                                                |
|-----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| [TileDB](https://github.com/TileDB-Inc/TileDB) ([feedstock](https://github.com/TileDB-Inc/tiledb-feedstock))   | [![tiledb](https://github.com/TileDB-Inc/conda-forge-nightly-controller/workflows/tiledb/badge.svg)](https://github.com/TileDB-Inc/conda-forge-nightly-controller/actions/workflows/tiledb.yml)          | [![tiledb-azure](https://dev.azure.com/TileDB-Inc/CI/_apis/build/status/tiledbfeedstock_CI?branchName=nightly-build)](https://dev.azure.com/TileDB-Inc/CI/_build/latest?definitionId=4&branchName=nightly-build)                 | [![version](https://anaconda.org/tiledb/tiledb/badges/version.svg)](https://anaconda.org/tiledb/tiledb)       | ![last updated](https://anaconda.org/tiledb/tiledb/badges/latest_release_date.svg)    | ![downloads](https://anaconda.org/tiledb/tiledb/badges/downloads.svg)    |
| [TileDB-Py](https://github.com/TileDB-Inc/TileDB-Py) ([feedstock](https://github.com/TileDB-Inc/tiledb-py-feedstock)) | [![tiledb-py](https://github.com/TileDB-Inc/conda-forge-nightly-controller/workflows/tiledb-py/badge.svg)](https://github.com/TileDB-Inc/conda-forge-nightly-controller/actions/workflows/tiledb-py.yml) | [![tiledb-py-azure](https://dev.azure.com/TileDB-Inc/CI/_apis/build/status/TileDB-Py%20Feedstock%20Testing?branchName=nightly-build)](https://dev.azure.com/TileDB-Inc/CI/_build/latest?definitionId=5&branchName=nightly-build) | [![version](https://anaconda.org/tiledb/tiledb-py/badges/version.svg)](https://anaconda.org/tiledb/tiledb-py) | ![last updated](https://anaconda.org/tiledb/tiledb-py/badges/latest_release_date.svg) | ![downloads](https://anaconda.org/tiledb/tiledb-py/badges/downloads.svg) |

## How it works

* The GitHub Actions workflows in the repository are scheduled run each night
  (they can also be manually triggered)

* The job clones both the TileDB-Inc fork of the feedstock repo and also the
  source repo

* The job updates the recipe (`meta.yaml`) to use the version string
  (X.X.X.YYYY_MM_DD), where X.X.X are derived from the source repo

* The job also updates the upload channels so that the conda binaries are
  uploaded to the [tiledb][anaconda.org-tiledb] channel on anaconda.org with the label "nightlies".

    [anaconda.org-tiledb]: https://anaconda.org/tiledb/tiledb/files?version=&channel=nightlies

* The job force pushes to the feedstock branch "nightly-build" to trigger Azure
  builds and uploads (this is made possible by manually configured SSH keys; see
  below)

## Run and test locally

To semi-reproduce the GitHub Actions workflows, run the following:

```sh
bash run-local-tiledb.sh
bash run-local-tiledb-py.sh

# To push changes to feedstock repos
# (not recommended unless GitHub Actions is broken)
bash run-local-tiledb.sh TRUE
# Wait for tiledb-feedstock runs to finish
bash run-local-tiledb-py.sh TRUE
```

To locally install a nightly version:

```sh
mamba create --yes -n test-nightlies \
  -c conda-forge -c "tiledb/label/nightlies" \
  --override-channels tiledb-py="*2022*"
```

## SSH keys

For each feedstock, generate a new SSH key pair:

1. Generate SSH keys on local machine. Hit enter twice to omit a password:

    ```sh
    mkdir /tmp/ssh-temp/
    ssh-keygen -t rsa -b 4096 -C "GitHub Actions for tiledb-nightlies" -f /tmp/ssh-temp/key
    head -n 1 /tmp/ssh-temp/key
    ## -----BEGIN RSA PRIVATE KEY-----
    ```

2. Add SSH private key (`/tmp/ssh-temp/key`) to tiledb-nightlies as a repository secret named
   `SSH_PRIVATE_KEY_<software>`:
    * Settings -> Secrets -> Actions -> New repository secret
    * Note: the name of the secret cannot include dashes (GitHub restriction)

3. Add SSH public key (`/tmp/ssh-temp/key.pub`) to TileDB-Inc fork of feedstock
   repository as a deploy key with write access:
    * Settings -> Deploy keys -> Add deploy key
    * Recommended to name it "tiledb-nightlies" to make the purpose of the key
      more obvious, but the name has no effect on functionality
    * Make sure to tick the box "Allow write access"!

4. Delete the keys locally. It's best practice to limit each key pair to only
   allow push access to a single repository, and regardless GitHub won't let you
   re-use them anyways

   ```sh
   rm -r /tmp/ssh-temp/
   ```

## Anaconda.org upload token (`BINSTAR_TOKEN`)

The instructions below are based off of the [conda-smithy][] instructions for
[making a new feedstock][making-a-new-feedstock].

[conda-smithy]: https://github.com/conda-forge/conda-smithy
[making-a-new-feedstock]: https://github.com/conda-forge/conda-smithy#making-a-new-feedstock

* (Once per GitHub org/user) Create an account on [Azure DevOps][azure]
  by authenticating with the corresponding GitHub user or org account.
  Importantly, you don't need to sign-up for the full Azure cloud experience to
  run Azure pipelines (I made this mistake, and now my inbox is flooded with
  Azure how-to emails)

    [azure]: https://dev.azure.com/

* (Once per GitHub org/user) Either pay for builds or apply for free builds for
  open source projects at https://aka.ms/azpipelines-parallelism-request. By
  default new Azure DevOps organizations are granted zero parallel builds, which
  means you can't run anything, even serially

* (Once per GitHub org/user) Create a new project named "feedstock-builds". This
  will be used to run the CI for all the feedstocks in your GitHub org/user. By
  default it is private. If you haven't already, you have to first allow public
  projects in your Azure DevOps account before you can make it public

* (Once per GitHub org/user) Connect the project "feedstock-builds" to your
  GitHub org/user via a "service connection". Go to "Project Settings" (bottom
  left in UI) -> "Service Connections" -> "Create Service Connection" -> GitHub.
  Grant it authorization via OAuth using the GitHub OAuth App AzurePipelines (to
  avoid having to generate a PAT). Name the service connection the same as your
  GitHub user/org

* Fork the conda-forge feedstock repo to your org/user account

* Clone the fork to your local machine

* (Once per machine) Install conda-smithy

    ```sh
    mamba install -c conda-forge conda-smithy
    ```

* Create an [Azure token][azure-token] and save it in
  `~/.conda-smithy/azure.token`

  [azure-token]: https://dev.azure.com/conda-forge/_usersSettings/tokens

* Run `conda smithy register-ci` in the local feedstock repo to activate builds
  on Azure DevOps. Note that you don't need to bother with the Anaconda token.
  Azure requires you to upload it manually later, so there's no point in saving
  it locally

    ```sh
    export AZURE_ORG_OR_USER="<your GitHub org/user>"
    # Switch --organization with --user for a GitHub user account
    conda smithy register-ci \
      --organization "<your GitHub org/user>" \
      --feedstock_directory . \
      --without-travis \
      --without-circle \
      --without-appveyor \
      --without-drone \
      --without-webservice \
      --without-anaconda-token
    ```

    If you were successful, you'll now see the new feedstock listed at `https://dev.azure.com/<account>/feedstock-builds/_build?view=folders`

* Create a token for anaconda.org
  * Login to your account at anaconda.org
  * Settings -> Access
  * Choose scope "Allow all API operations". I couldn't find any documentation
    that linked the scopes to allowable actions. I tried "Allow all operations
    on Conda repositories", but that failed due to insufficient permissions.

* Add the anaconda.org token as a pipeline variable on Azure. From the pipeline
  page: Edit -> Variables -> New variable -> Name it `BINSTAR_TOKEN` ->
  Copy-paste token -> Check "Keep this value secret" -> OK -> Save
