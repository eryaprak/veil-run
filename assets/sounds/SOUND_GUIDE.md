# Veil Run - Sound Assets

## Music
- **Menu Theme:** Ambient electronic, mysterious, 80-100 BPM
  - Sources: Pixabay Music Library (CC0), Freesound.org
  - Example: "Cyber Dreams" style, dark synth pads

- **Gameplay Theme:** Uptempo electronic with Middle Eastern fusion
  - 120-140 BPM, driving beat
  - Layered: electronic bass + oud/ney samples
  - Loop: 2-3 minutes
  - Sources: Incompetech (Kevin MacLeod CC-BY), Purple Planet Music

## SFX
- **Veil Shift:** Whoosh + shimmer, 0.3s
- **Coin Collect:** Bright chime, 0.2s
- **Obstacle Hit:** Dark impact + glass shatter, 0.4s
- **Checkpoint:** Celebration chime progression, 1s
- **UI Button:** Soft click, 0.1s
- **Death:** Low drone + reverb, 1.5s

## Implementation Notes
- Format: OGG Vorbis (Godot preferred)
- Sample rate: 44.1kHz
- Bitrate: 128kbps (music), 96kbps (SFX)
- Use AudioStreamPlayer for music (autoplay loop)
- Use AudioStreamPlayer2D for positional SFX

## Free Sources
1. Freesound.org (CC0, CC-BY)
2. Pixabay Music & SFX (CC0)
3. OpenGameArt.org
4. Incompetech (Kevin MacLeod, CC-BY 4.0)
5. Purple Planet Music (free for commercial)

## Temporary Placeholders
For MVP sprint, use silent audio streams or basic sine wave tones.
Polish with actual audio in v1.1 if time permits.
