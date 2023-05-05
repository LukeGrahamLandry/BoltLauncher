
## 23.01.19

- better apple silicon support by bumping lwjgl for 1.18.x and forge 1.16.5

## 23.01.14

- find curseforge profiles and can launch from their directory

## 23.01.12

- testing 1.18.2-1.13.2, only works with rosetta

## 23.01.09

- integration test that launches the game for all supported loader/version combinations in sequence 

## 23.01.08

- find existing java installations

## 23.01.06

- install and launch forge

## 23.01.05

- process files as streams so the whole thing isn't in memory at once
- symlink to files in well known install locations (mojang, curseforge, prism) instead of downloading when possible

## 23.01.04

- retry failed downloads
- store asset index hash in manifest instead of rechecking files 

## 23.01.03

- download extra assets (sounds, main menu background, etc)
- install and launch quilt
- install and launch fabric
- more detailed logging during downloading

## 23.01.02

- launch the game
- download natives 
- async downloading (faster)
- check hashes of downloaded files
- download mods from cursemaven

## 23.01.01

- install vanilla
