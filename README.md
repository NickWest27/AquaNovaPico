# Aqua Nova

A Pico-8 game created with Claude AI collaboration.

## About

Aqua Nova is an underwater adventure game for Pico-8. This project demonstrates collaboration between human creativity and AI assistance using GitHub for version control.

## Project Structure

- `aqua_nova.p8` - Main game file (Pico-8 cartridge)
- `src/` - Source code organized by module
  - `main.lua` - Entry point and game loop
  - `player.lua` - Player entity and mechanics
  - `enemies.lua` - Enemy definitions and behavior
  - `world.lua` - Level and world management
  - `utils.lua` - Helper functions and utilities
- `docs/` - Game design documents
  - `design.md` - Game design document
  - `technical.md` - Technical notes
- `.gitignore` - Git configuration

## Getting Started

### Requirements
- [Pico-8](https://www.lexaloffle.com/pico-8.php)
- Text editor or IDE (VS Code recommended)
- Git

### Setup
1. Install Pico-8
2. Clone this repository
3. Open `aqua_nova.p8` in Pico-8
4. Run the game with `pico8 aqua_nova.p8`

## Development Workflow

1. Edit code in the `src/` directory
2. Update the main `aqua_nova.p8` file with changes
3. Test in Pico-8
4. Commit changes to git with clear messages
5. Push to GitHub

## Collaboration with AI

When collaborating with Claude AI:
- Describe the feature or bug you want to address
- Ask for code suggestions or implementation help
- Use AI to review and improve code
- Maintain clear commit messages for AI context

## Controls

- Arrow Keys / WASD - Move
- Z / C - Action button
- X - Cancel button

## License

[Choose your license - e.g., MIT, CC0]

## Notes

- Pico-8 uses Lua as its scripting language
- Color palette is limited to 16 colors
- Screen resolution is 128x128 pixels
