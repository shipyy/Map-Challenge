# Map-Challenge

*This plugin is suposed to be used alongside* [SurfTimer](https://github.com/surftimer/SurfTimer)

Allows the creation of challenges and the customization of them.
You can customize the map, style, duration of the callenge and points received.

## Installation

* Download Release Files and simply drag and drop onto your csgo folder

## Requirements

**Plugins**
* [SurfTimer](https://github.com/surftimer/SurfTimer)
* [SurfTimer-Discord](https://github.com/surftimer/SurfTimer-discord) (*optional*)

## Showcase

# Challenge info display
![image](https://user-images.githubusercontent.com/70631212/174004494-50fceb52-9c6f-4d9d-8338-a75c5e864028.png)

# Ongoing Challenge Top Players with times
![image](https://user-images.githubusercontent.com/70631212/174004447-840e1c62-3551-4584-8843-80d618d7f24c.png)

# Discord Notification When A new challenge is created
![image](https://user-images.githubusercontent.com/70631212/180581059-6021cabf-eb82-4ebb-97e6-81e106ed8336.png)

## More Details
To create a new challenge ```sm_add_challenge <mapname> <style> <top1_points> <duration (in days)>```.
The plugin only allows 1 challenge occuring at the same time (for now idk).
An admin can end the current challenge via cmd, which will also distribute the points accordingly.
The point distribution is done automatically either when an admin uses the ```sm_end_challenge``` cmd OR when the duration of the challenge has reached the final date

## Future Ideas
* Discord Integration (Done)
* Multiple Challenges (?)
* Better point distribuition (?)
* Add discord notification when the challenge has ended with the player who won
