# Map-Challenge

*This plugin is suposed to be used alongside* [SurfTimer](https://github.com/surftimer/SurfTimer)

Allows the creation of challenges and the customization of them.
You can customize the map, style, duration of the callenge and points received.

## Installation

* Download Release Files and simply drag and drop onto your csgo folder

`csgo/addons/sourcemod/plugins/Map_Challenge.smx`

`csgo/addons/sourcemod/scripting/include/map-challenge.inc`

`csgo/addons/sourcemod/translations/mapchallenge.phrases.txt`

## Requirements

**Plugins**
*  (*required*) [SurfTimer](https://github.com/surftimer/SurfTimer)
* (*optional*) [SurfTimer-Discord](https://github.com/surftimer/SurfTimer-discord)

## Showcase
# Current Challenge info display
![image](https://user-images.githubusercontent.com/70631212/180694878-e4dd13df-1167-4d30-b776-e7d54fb3d746.png)
![image](https://user-images.githubusercontent.com/70631212/180694922-88967f02-ece8-49a7-a5e1-ff4891213250.png)

# Current Challenge Leaderboard
![image](https://user-images.githubusercontent.com/70631212/180695169-cec8d76d-6776-4bd2-b226-6df7ccdf4968.png)

# Challenge Player Profiles
![image](https://user-images.githubusercontent.com/70631212/180695226-55b0cba5-9e40-455c-82a6-ccda854fffdb.png)

# Discord Integration 
## Notification when a challenge is created
![image](https://user-images.githubusercontent.com/70631212/180698128-4f3b07bf-f030-413d-ab06-81f10cba349d.png)

## Notification when a challenge ends
![image](https://user-images.githubusercontent.com/70631212/183961337-c9a06953-b6f6-40a9-81fa-8467be4f895b.png)

## How To

Command | Description | Usage
:---|:---|:---:
`sm_add_challenge` | Add new challenge | ```sm_add_challenge <mapname> <style> <top1_points> <duration>``` *duration is in days*
`sm_end_challenge` | Ends the ongoing challenge |
`sm_challenge` | Displays additional information of the ongoing challenge |
`sm_mcp` | Displays the players profile |
`sm_mctop` | Displays the overall challenge top players (TOP 50) |
`sm_mcct` | Displays the ongoing challenge leaderboard (TOP 50) |
`sm_mct` | Displays remaining time left of the current challenge |

## More Details
* The plugin only allows 1 challenge occuring at the same time (for now idk)
* If there is a challenge on going, it will automatically stop if it reaches the `final date` OR if an admin uses `sm_end_challenge`
* The point distribution is done automatically when a challenge ends
* If there is a challenge on going all players ingame will be notified in which map it is
* When used with [SurfTimer-Discord](https://github.com/surftimer/SurfTimer-discord) (*optional*) it allows you to set a custom role name for pings

## Future Ideas
* Discord Integration (Done)
* Multiple Challenges (?)
* Better point distribuition (?)
* Add discord notification when the challenge has ended with the player who won (Done)
