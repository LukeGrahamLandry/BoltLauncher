# Forking 

You're totally welcome to fork BoltLauncher as a starting point for your own project. It would be nice of you to credit where it came from and link back to this repository. 

The project is structured so that you should be able to do all your customization in the `gui` section, to get it looking and behaving how you want, without ever needing to change anything in the `lib` section. 'lib' has the logic for actually handling installation and launching based on the requests from `gui`. 

## Configuration 

The settings in `gui/config.dart` allow you to create a white labeled custom build if you fork BoltLauncher. 

- launcher name
- home page display url
- list of mod packs installed by default 
- azure client id (for microsoft login)
    - *this can also passed in from the command line at build time because committing it feels awkward* 
- app cast feed url (for automatic launcher updates)
- name of the folder to store installations in 
- privacy policy text
    - *make sure this accurately reflects what you player data you collect*
- license text
    - *the original source is under the Unlicense. If you want to change it for your version, make sure to remove the license file from the repo as well*
- interface mode
    - **LibreMode**: Players can install any mods and mod packs they want. The launcher functions like Curseforge's launcher basically. 
    - **ManagedMode**: You hardcode a mod pack (or multiple) to be installed (and updated) automatically. The launcher will not show pages to install other mods or mod packs. Useful if the purpose of your launcher is solely to keep your players up to date with your server's mods. 

The default meta urls are in `lib/src/data/options.dart`. 

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
