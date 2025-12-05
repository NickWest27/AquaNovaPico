# Aqua Nova - Technical Documentation

## Project Structure
```
AquaNovaPico/
├── README.md
├── aqua_nova.p8
├── src/
│   ├── main.lua      # Game entry point and main loop
│   ├── player.lua    # Player entity and mechanics
│   ├── enemies.lua   # Enemy definitions and AI
│   ├── world.lua     # Level and world management
│   └── utils.lua     # Helper functions
├── docs/
│   ├── design.md     # Game design document
│   └── technical.md  # This file
└── .gitignore
```

## Pico-8 Specifics
- **Language**: Lua
- **Screen Resolution**: 128x128 pixels
- **Color Palette**: 16 colors
- **Sprites**: 8x8 pixel sprites
- **Token Limit**: 8192 tokens

## Key Functions

### Main Loop
- `_init()`: Called once at startup
- `_update()`: Called each frame for game logic
- `_draw()`: Called each frame for rendering

### Module System
Each module (player, enemies, world) returns a table with methods:
- `.create()` or `.init()` - Initialize
- `.update()` - Update logic
- `.draw()` - Render

## Performance Considerations
- Keep draw calls minimal
- Use sprites efficiently
- Avoid unnecessary table allocations per frame
- Test with larger numbers of enemies

## Development Tips
1. Test frequently in Pico-8
2. Use the built-in debugger for breakpoints
3. Keep code modular for easier AI collaboration
4. Document complex algorithms
5. Use meaningful variable names

## Git Workflow
1. Create feature branches for new features
2. Commit frequently with clear messages
3. Include what changed and why
4. Push to GitHub regularly
