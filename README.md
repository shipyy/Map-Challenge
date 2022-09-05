# Map-Challenge

*This plugin is suposed to be used alongside* [SurfTimer](https://github.com/surftimer/SurfTimer)

Allows the creation of challenges and the customization of them.
You can customize the map, style, duration of the callenge and points received.

## Installation

* Download [latest release](https://github.com/shipyy/Map-Challenge/releases/latest), exctract and drop the contents of `MapChallenge.zip` into your `csgo/addons/sourcemod` folder

***NOTE***

if you are using **Maria DB**, before restarting server after dropping installation files run this query:
`CREATE TABLE IF NOT EXISTS ck_challenge_times (id INT(12) NOT NULL, steamid VARCHAR(32), name VARCHAR(32), mapname VARCHAR(32), runtime decimal(12, 6) NOT NULL DEFAULT '0.000000', style INT(12) NOT NULL DEFAULT '0', Run_Date TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), PRIMARY KEY(id, steamid, mapname, runtime)) DEFAULT CHARSET=utf8mb4;`


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

Command | Description
:---|:---
`sm_add_challenge` | Add new challenge
`sm_end_challenge` | Ends the ongoing challenge
`sm_challenge` | Displays additional information of the ongoing challenge
`sm_mcp` | Displays the players profile
`sm_mctop` | Displays the overall challenge top players (TOP 50)
`sm_mcct` | Displays the ongoing challenge leaderboard (TOP 50)
`sm_mct` | Displays remaining time left of the current challenge

### Prefixes

<table
<tr><th>Style</th><th>Time</th></tr>
<tr><td>

Prefix | Description
:---|:---
n | Normal
sw | Sideways
hsw | Half-Sideways
bw | Backwards
lg | Low-Gravity
sm | Slow Motion
ff | Fast Forward
fs | Freestyle

</td><td>

Prefix | Description
:---|:---
 **d** OR **D** | Days
 **h** OR **H** | Hours
 **m** OR **M** | Minutes

</td></tr> </table>

### Examples of creating a New Challenge

**Command Format** - ```sm_add_challenge <mapname> <style> <top1_points> <<time_prefix>duration>```

```/add_challenge surf_beginner #n 420 d1.5``` - Creates a Challenge for ***1 day and a half*** in ***Normal*** style with the ***Winner*** receiving 420 points\
```/add_challenge surf_beginner #hsw 666 h0.5``` - Creates a Challenge for ***half an hour*** in ***Half-Sideways*** style with the ***Winner*** receiving 666 points

## More Details
* The plugin only allows 1 challenge occuring at the same time (for now idk)
* If there is a challenge on going, it will automatically stop if it reaches the `final date` OR if an admin uses `sm_end_challenge`
* The point distribution is done automatically when a challenge ends
* If there is a challenge on going all players ingame will be notified in which map it is
* When used with [SurfTimer-Discord](https://github.com/surftimer/SurfTimer-discord) (*optional*) it allows you to set a custom role name for pings

## Future Ideas
* Discord Integration (Done)
* Multiple Challenges (Coming Soon TM)
* Better point distribuition (?)
* Add discord notification when the challenge has ended with the player who won (Done)
* Racing (1vs1) (In development)
