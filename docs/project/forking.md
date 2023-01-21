# Forking 

You're totally welcome to fork BoltLauncher as a starting point for your own project. It would be nice of you to credit where it came from and link back to this repository. I'd also appreciate it if you keep the link to my commissions website in the sidebar. The money from that is what allows me do keep releasing fun open source projects like this.

Whenever possible, I'd encourage contributing pull requests back to the original project with any new features that you develop instead of starting separate projects. Having a fractured group of projects that all support a different subset of available features forces players to choose between them instead of having access to the best of everything. If for some strange reason I don't accept your PR, you have my blessing to distribute custom builds yourself. 

## Building 

Once your code is ready, you'll want to run the app to test it out or build a release. 

### Local

- [Install the Dart SDK](https://dart.dev/get-dart)
- Run code generation: (for json parsing)
    - one time: `dart run build_runner build --delete-conflicting-outputs`
    - continuous: `dart run build_runner watch --delete-conflicting-outputs`
- Run command line app: `dart run cli/main.dart`
- Build command line app: `dart compile exe cli/main.dart -o bolt`
    - Use the `--define=AZURE_CLIENT_ID=put_your_azure_client_id_here` option to specify your Microsoft identity platform key. 
    - The `bolt` file will be created. It's an executable built for your current operating system. 

### Github Actions

If you fork the github repository, a github action is already setup to automatically build the project every time you push new changes. The build will run for for mac, windows, and linux. The build artifacts can be downloaded by selecting the latest run from the Actions tab of your repository and scrolling down to the Artifacts section. Github actions is [free for public repositories](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions). 

- You can add `AZURE_CLIENT_ID` as a secret on your repository and it will be used in the build automatically. 

## Configuration 

If you're distributing the fork yourself rather than just submitting a PR, you'll probably want to customize the branding of the application. The settings in `gui/config.dart` allow you to create a white labeled custom build from your fork. 

- launcher name
- home page display url
- list of mod packs installed by default 
- azure client id (for microsoft login)
    - *this can also passed in from the command line at build time because committing it to git feels awkward* 
- app cast feed url (for automatic launcher updates)
- name of the folder to store installations in 
- privacy policy text
    - *make sure this accurately reflects what you player data you collect*
- license text
    - *the original source is under the Unlicense. If you want to change it for your version, make sure to remove the license file from the repo as well*

The default meta urls are in `lib/src/data/options.dart`. 
