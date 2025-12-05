# Aqua Nova Pico

A submarine strategy simulation game for Pico-8, inspired by SeaQuest DSV and Star Trek.

## Overview

Command a deep-sea research submarine as you navigate treacherous waters, conduct scientific experiments, manage resources, and complete critical missions. Balance power allocation, resource consumption, and strategic decisions to succeed in the depths.

## Game Concept

Aqua Nova Pico is a **strategy-first submarine game** where you make command decisions across multiple stations. Rather than arcade-style action, the game focuses on:

- Strategic navigation and route planning
- Resource management (money, food, supplies, power)
- Scientific discovery and experimentation
- Reputation-based progression
- Risk vs. reward decision-making

## Core Gameplay Loop

1. **Accept Mission** - Choose from available contracts based on your reputation
2. **Plan Route** - Plot waypoints to objectives while considering hazards
3. **Manage Resources** - Balance speed, power consumption, and supplies
4. **Execute Mission** - Navigate, collect samples, avoid dangers
5. **Return to Port** - Resupply, repair, upgrade equipment
6. **Build Reputation** - Unlock new missions and regions

## Resource System

### Primary Resources
- **Money** - Earned through mission completion, spent on supplies at port
- **Food** - Consumed daily, crew morale depends on adequate supplies
- **Supplies** - Used for experiments, repairs, and mission objectives
- **Reactor Power** - Degrades over time, powers all ship systems
- **O2 Scrubbers** - Efficiency decreases with use, requires power to operate
- **Reputation** - Affects mission availability and port prices

### Strategic Balance
- **Speed** - Faster movement = higher collision risk, can't perform detailed scans
- **Power** - Limited reactor output must be allocated across systems
- **Time** - Rescue missions have deadlines, longer missions drain more food
- **Hull Integrity** - Damaged by collisions and weapons, not by pressure

## Station Overview

### Bridge/Navigation
- View tactical map with waypoints and features
- Plot routes to destinations
- Monitor submarine position, heading, depth
- Track mission objectives

### Helm Control
- Adjust heading (compass interface)
- Set speed (0-160 knots)
- Control depth (0-1200 meters)
- Real-time submarine maneuvering

### Science Station
*(In Development)*
- Collect environmental samples
- Perform experiments (consumes supplies)
- Analyze findings for mission completion
- Document discoveries

### Power Management
*(In Development)*
- Allocate reactor output to ship systems
- Balance propulsion, sensors, life support
- Monitor O2 scrubber efficiency
- Emergency power routing

### Captains Quarters (Status Report)
- View all resources at a glance
- Check mission progress and tasks
- Monitor submarine health
- Control game settings

## Controls

### General
- **Arrow Keys** - Move cursor to select context/variable
- **🅾️ (Z Key)** - Back/No
- **❎ (X Key)** - Context action/Yes

### Navigation/Bridge
- **Arrow Keys** - Move cursor on map
- **❎** - Place waypoint at cursor position

## Mission Types (Planned)

- **Deep Canyon Survey** - Navigate dangerous terrain to collect geological samples
- **Thermal Vent Discovery** - Locate and study underwater volcanic activity
- **Salvage & Rescue** - Find downed vessels and recover critical data
- **Species Documentation** - Photograph and catalog rare marine life
- **Time-Critical Rescue** - Save survivors before oxygen runs out


## Development Status

### ✅ Implemented
- Multi-station interface system
- Basic navigation with waypoint plotting
- Helm controls (heading, speed, depth)
- Resource tracking (money, food, supplies)
- Time progression and daily resource consumption
- Map display with features (ports, sample sites)
- System degradation (reactor, O2 scrubbers)

### 🚧 In Progress
- Auto-navigation along waypoint routes
- Port docking and resupply mechanics
- Sample collection and analysis
- Mission system and objectives

### 📋 Planned Features
- Power allocation system
- Collision detection and terrain
- Multiple ocean regions to unlock
- Submarine upgrades and equipment loadouts
- Reputation-based mission progression
- Sonar and sensor mechanics
- Random events and encounters
- Save/load game state

## Design Philosophy

**Inspired by Classic Submarine/Spaceship Shows:**
- Decision-making over twitch reflexes
- Resource scarcity creates tension
- Multiple systems require attention
- Strategic planning rewards careful players
- "Captain's chair" experience

**Pico-8 Constraints as Features:**
- Limited screen space forces focused interfaces
- Simplified controls promote accessibility
- Retro aesthetic enhances charm
- Code limit encourages elegant solutions

## Technical Details

- **Platform:** Pico-8 (Lua-based fantasy console)
- **Resolution:** 128x128 pixels, 16-color palette
- **Code Limit:** 32KB compressed
- **Language:** Lua (subset)

## Contributing

This is an active development project. Feedback, bug reports, and feature suggestions are welcome!

### Areas for Contribution
- Mission design and balancing
- UI/UX improvements
- Additional station mechanics
- Sound effects and music
- Sprite art and animations

## Influences & Inspiration

- **SeaQuest DSV** - Submarine exploration and crew dynamics
- **Star Trek** - Bridge stations and power management
- **FTL: Faster Than Light** - Strategic decision-making and resource management
- **Silent Hunter Series** - Submarine simulation depth
- **Sea Rogue (DOS)** - Classic underwater strategy

## License

**

## Credits

Created by Nicholas Westmoreland with help from Claude AI

Special thanks to the Pico-8 community for inspiration and resources.

---

**Current Version:** 0.1-alpha  
**Status:** Early Development  
**Last Updated:** December 2025
