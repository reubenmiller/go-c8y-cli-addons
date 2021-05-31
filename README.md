## Notice

This repository is meant to compliment the [go-c8y-cli](https://github.com/reubenmiller/go-c8y-cli) project by providing the following:

* Installation script
* Default views
* Template (jsonnet) examples
* Shell profile helpers (i.e. `set-session`)

Please see the [documentation](https://goc8ycli.netlify.app/docs/installation/shell-installation) for more information.

## Getting started

1. Clone the repository

    **Shell (bash/zsh/fish)**

    ```sh
    git clone https://github.com/reubenmiller/go-c8y-cli-addons.git ~/.go-c8y-cli
    cd ~/.go-c8y-cli
    ```

    **PowerShell**

    ```sh
    git clone https://github.com/reubenmiller/go-c8y-cli-addons.git $HOME/.go-c8y-cli
    cd $HOME/.go-c8y-cli
    ```

2. Install go-c8y-cli binary

    **Option 1: without sudo**

    ```sh
    ~/.go-c8y-cli/install.sh
    ```

    **Option 2: with sudo**
    If you want to make the c8y globally available, then you can run it using sudo, which will install it under `/usr/local/bin`.

    ```sh
    sudo -E ~/.go-c8y-cli/install.sh
    ```

    **PowerShell**

    ```sh
    & "$HOME/.go-c8y-cli/install.ps1"
    ```

3. Create a new session (if you do not already have one)
    
    ```sh
    c8y sessions create --host myinfo --username johnsmith@example.com --type dev
    ```

4. Activate the newly create profile

    ```sh
    set-session
    ```

5. Check the profile by showing your current user information

    ```sh
    c8y currentuser get
    ```

## Upgrading to latest version

1. Run the install script again

    **Shell (bash/zsh/fish)**

    ```sh
    ~/.go-c8y-cli/install.sh
    ```

    **PowerShell**

    ```sh
    & $HOME/.go-c8y-cli/install.ps1
    ```

    **Note**

    go-c8y-cli will only be updated if you are not running the latest version already.
