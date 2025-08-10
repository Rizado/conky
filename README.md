# .conky
Very thanks to @wim66 for original code, this project is based on it. All code is refactored and optimized.

But there is many changes:

1. All functions are placed into one file. There are no more files bars.lua, background.lua etc.
2. Removed duplicates of functions (rgb_to_r_g_b_a, hex_to_rgba, rgb_to_r_g_b_a2 etc) and changed all calls of these functions. All functions exist in one instance.
3. Code and data are separated. This is main. You don't need to edit file with code for change options. Use the same file with code for all instances of Conky.
4. Count of create/destroy canvas is reduced.
5. Some functions were rewritten completely.
