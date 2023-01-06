
## 23.01.05-dev

- copy files from well known install locations (mojang, curseforge, prism) instead of downloading when possible
- process files as streams so the whole thing isn't in memory at once

## 23.01.04-dev

- retry failed downloads
- store asset index hash in manifest instead of rechecking files 

## 23.01.03-dev

- download extra assets (sounds, main menu background, etc)
- install and launch quilt
- install and launch fabric
- more detailed logging during downloading

## 23.01.02-dev

- launch the game
- download natives (TODO: extract, pre 1.19)
- async downloading (faster)
- check hashes of downloaded files
- download mods from cursemaven

## 23.01.01-dev

- install vanilla
