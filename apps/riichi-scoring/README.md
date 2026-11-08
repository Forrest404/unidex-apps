# Rii Mahjong Scoring

A quick score lookup tool for Riichi Mahjong, supporting hands from 1 han up to Kazoe Yakuman (13+ han). 

## Features
- Calculates both Ron and Tsumo values for Dealer and Non-Dealer.
- Includes a toggle for **Kiriage Mangan** (rounding up 4 han 30 fu and 3 han 60 fu to Mangan).
- Automatically handles limit hands (Mangan, Haneman, Baiman, Sanbaiman, Yakuman) when 5+ han is selected.
- Shows "-" for impossible hands (e.g., 1 han 20 fu).
- Fu values are ordered by real-game frequency for faster input.

## Buttons

- **Menu:** 
  - Press A = Start
  - Press B = Toggle Kiriage Mangan ON/OFF
  - Hold A = Exit
- **Input:**
  - Press A = Next field
  - Press B = Cycle current value
  - Hold B = Back a field (or back to Menu from the first field)
- **Result:**
  - Press A = Nothing
  - Press B = New score (resets to 1 han, 30 fu)
  - Hold A = Exit

## Data files

None. The app keeps nothing between sessions.