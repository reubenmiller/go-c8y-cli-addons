## Notice

WIP - Work in Progress

## Getting started

1. Clone the repository

    ```sh
    git clone https://github.com/reubenmiller/go-c8y-cli-addons.git ~/.go-c8y-cli
    cd ~/.go-c8y-cli
    ```

2. Install go-c8y-cli binary

    ```sh
    sudo -E ~/.go-c8y-cli/install.sh
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

    ```sh
    ~/.go-c8y-cli/install.sh
    ```

    **Note**

    go-c8y-cli will only be updated if you are not running the latest version already.
