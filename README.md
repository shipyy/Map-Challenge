# Map-Challenge

*This plugin is suposed to be used alongside* [SurfTimer](https://github.com/surftimer/SurfTimer)

Allows the creation of challenges and the customization of them.
You can customize the map, style, duration of the callenge and points received.

## Installation

* Download Release Files and simply drag and drop onto your csgo folder
* Run Query -> "ALTER TABLE ck_playerrank ADD challenge_points int(11) NOT NULL DEFAULT '0';"
* Merge Following Commits to your Surftimer code.
  * https://github.com/shipyy/Surftimer-Official/commit/e2001205b0e80c4ccc8cf6440bb49ec67850dee1
  * https://github.com/shipyy/Surftimer-Official/commit/4c671ce35f356b74297ab71acc09b4bc147e6efe

## Requirements

**Libraries**
* [Surftimer.inc](https://github.com/shipyy/Map-Challenge/blob/main/include/surftimer.inc)
* [ColorLib](https://github.com/c0rp3n/colorlib-sm)

**Plugins**
* [SurfTimer](https://github.com/surftimer/SurfTimer)

**Commits**
* https://github.com/shipyy/Surftimer-Official/commit/e2001205b0e80c4ccc8cf6440bb49ec67850dee1
* https://github.com/shipyy/Surftimer-Official/commit/4c671ce35f356b74297ab71acc09b4bc147e6efe

## Showcase

# Challenge info display
![image](https://user-images.githubusercontent.com/70631212/174004494-50fceb52-9c6f-4d9d-8338-a75c5e864028.png)

# Challenge Top Players with times
![image](https://user-images.githubusercontent.com/70631212/174004447-840e1c62-3551-4584-8843-80d618d7f24c.png)

## More Details
To create a new challenge ```sm_add_challenge <mapname> <style> <top1_points> <duration (in days)>```.
The plugin only allows 1 challenge occuring at the same time (for now idk).
An admin can end the current challenge via cmd, which will also distribute the points accordingly.
The point distribution is done automatically either when an admin uses the ```sm_end_challenge``` cmd OR when the duration of the challenge has reached the final date

## Future Ideas
* Discord Integration (working on it)
* Multiple Challenges
* Better point distribuition ?
