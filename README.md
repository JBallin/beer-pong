# AR Beer Pong

## Background
For my final project at Galvanize's Web Development Immersive I needed to choose a new language; naturally I chose Swift given my Apple [fanaticism](https://apple.stackexchange.com/users/151404/jballin).

I've been fascinated with Virtual and Augmented reality since the early days, so I wanted to try something with ARKit. Beer Pong seemed like a fun way to get started!

## Description
In this game, you can place a realistically sized table on the floor and toss balls into cups until they all disappear. This involved building 3D objects both directly and with code, including physics (static vs. dynamic, force, friction, restitution etc.) and geometry (x, y, z coordinates, shapes, sizing).

## Demo (GIF)
<img src="demo.gif" alt="screenshot" height=300px>

Also: Check out my [progress video](https://youtu.be/is4Vgu8Lexg) (26s)

## Tech
Built in Swift (iOS) using Xcode (Apple IDE), utilizing the following Apple frameworks:

* SceneKit – 3D graphics, animations, physics
* ARKit – Camera, motion sensors
* UIKit – Touch gesture

## Challenges
* Learned Swift in 1 week and built my first AR app in 1 week!
* SceneKit and ARKit are new so resources online are scarce
* Working with physics, geometry, 3D design, realistic sizing, apply
force based on camera orientation
* Plane detection, Hit Tests, Collision Tests
