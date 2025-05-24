#!/usr/bin/env python3
import curses
import random
import time
from collections import deque

class GameObject:
    def __init__(self, x, y, char, color):
        self.x = x
        self.y = y
        self.char = char
        self.color = color

    def draw(self, stdscr):
        stdscr.addch(self.y, self.x, self.char, curses.color_pair(self.color))

class Player(GameObject):
    def __init__(self, x, y):
        super().__init__(x, y, '@', 1)
        self.health = 100
        self.strength = 10
        self.weapons = ["fists"]
        self.traps = 0

class Enemy(GameObject):
    def __init__(self, x, y, enemy_type="goblin"):
        colors = {"goblin": 2, "orc": 3, "ghost": 4}
        chars = {"goblin": 'g', "orc": 'O', "ghost": '&'}
        health = {"goblin": 20, "orc": 40, "ghost": 15}
        super().__init__(x, y, chars[enemy_type], colors[enemy_type])
        self.health = health[enemy_type]
        self.strength = random.randint(5, 15)
        self.type = enemy_type

    def take_damage(self, damage):
        self.health -= damage
        return self.health <= 0

class Weapon(GameObject):
    def __init__(self, x, y, weapon_type="sword"):
        colors = {"sword": 5, "bow": 6, "axe": 7}
        chars = {"sword": '/', "bow": '}', "axe": '\\'}
        super().__init__(x, y, chars[weapon_type], colors[weapon_type])
        self.type = weapon_type
        self.damage = {"sword": 15, "bow": 10, "axe": 20}[weapon_type]

class Trap(GameObject):
    def __init__(self, x, y):
        super().__init__(x, y, '^', 8)
        self.damage = 25

class Game:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        self.running = True
        self.game_over = False
        self.wave = 1
        self.score = 0
        self.message_log = deque(maxlen=5)
        
        # Initialize colors
        curses.start_color()
        curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)  # Player
        curses.init_pair(2, curses.COLOR_RED, curses.COLOR_BLACK)    # Goblin
        curses.init_pair(3, curses.COLOR_YELLOW, curses.COLOR_BLACK) # Orc
        curses.init_pair(4, curses.COLOR_WHITE, curses.COLOR_BLACK)   # Ghost
        curses.init_pair(5, curses.COLOR_BLUE, curses.COLOR_BLACK)    # Sword
        curses.init_pair(6, curses.COLOR_CYAN, curses.COLOR_BLACK)    # Bow
        curses.init_pair(7, curses.COLOR_MAGENTA, curses.COLOR_BLACK) # Axe
        curses.init_pair(8, curses.COLOR_RED, curses.COLOR_BLACK)     # Trap
        
        # Game setup
        self.map_width = 30
        self.map_height = 15
        self.player = Player(self.map_width // 2, self.map_height // 2)
        self.enemies = []
        self.weapons = []
        self.traps = []
        self.spawn_weapons(2)
        self.spawn_enemies(3)

    def spawn_enemies(self, count):
        enemy_types = ["goblin", "orc", "ghost"]
        for _ in range(count):
            x, y = self.random_position()
            self.enemies.append(Enemy(x, y, random.choice(enemy_types)))

    def spawn_weapons(self, count):
        weapon_types = ["sword", "bow", "axe"]
        for _ in range(count):
            x, y = self.random_position()
            self.weapons.append(Weapon(x, y, random.choice(weapon_types)))

    def random_position(self):
        while True:
            x = random.randint(1, self.map_width - 2)
            y = random.randint(1, self.map_height - 2)
            if (x, y) != (self.player.x, self.player.y):
                return x, y

    def add_message(self, message):
        self.message_log.append(message)

    def handle_input(self):
        key = self.stdscr.getch()
        
        if key == ord('q'):
            self.running = False
        elif key == ord('a'):  # Attack
            self.attack_enemies()
        elif key == ord('t'):  # Place trap
            self.place_trap()
        elif not self.game_over:
            if key == curses.KEY_UP:
                self.move_player(0, -1)
            elif key == curses.KEY_DOWN:
                self.move_player(0, 1)
            elif key == curses.KEY_LEFT:
                self.move_player(-1, 0)
            elif key == curses.KEY_RIGHT:
                self.move_player(1, 0)

    def move_player(self, dx, dy):
        new_x, new_y = self.player.x + dx, self.player.y + dy
        if 0 < new_x < self.map_width - 1 and 0 < new_y < self.map_height - 1:
            self.player.x, self.player.y = new_x, new_y

    def attack_enemies(self):
        for enemy in self.enemies[:]:
            if abs(self.player.x - enemy.x) <= 1 and abs(self.player.y - enemy.y) <= 1:
                damage = self.player.strength
                if self.player.weapons[-1] != "fists":
                    damage += next(w.damage for w in self.weapons if w.type == self.player.weapons[-1])
                
                if enemy.take_damage(damage):
                    self.enemies.remove(enemy)
                    self.score += 10
                    self.add_message(f"You killed the {enemy.type}!")
                else:
                    self.add_message(f"You hit the {enemy.type}! (HP: {enemy.health})")

    def place_trap(self):
        if self.player.traps > 0:
            self.traps.append(Trap(self.player.x, self.player.y))
            self.player.traps -= 1
            self.add_message("Trap placed!")
        else:
            self.add_message("No traps left!")

    def update(self):
        if self.game_over:
            return

        # Check weapon pickup
        for weapon in self.weapons[:]:
            if (self.player.x, self.player.y) == (weapon.x, weapon.y):
                self.player.weapons.append(weapon.type)
                self.weapons.remove(weapon)
                self.add_message(f"You picked up a {weapon.type}!")

        # Check trap triggers
        for trap in self.traps[:]:
            for enemy in self.enemies[:]:
                if (enemy.x, enemy.y) == (trap.x, trap.y):
                    if enemy.take_damage(trap.damage):
                        self.enemies.remove(enemy)
                        self.score += 10
                        self.add_message(f"Trap killed {enemy.type}!")
                    self.traps.remove(trap)
                    break

        # Enemy movement & attacks
        for enemy in self.enemies:
            # Simple AI: move toward player
            dx = 1 if enemy.x < self.player.x else -1 if enemy.x > self.player.x else 0
            dy = 1 if enemy.y < self.player.y else -1 if enemy.y > self.player.y else 0
            enemy.x += dx
            enemy.y += dy

            # Enemy attack
            if abs(enemy.x - self.player.x) <= 1 and abs(enemy.y - self.player.y) <= 1:
                self.player.health -= enemy.strength
                self.add_message(f"{enemy.type} hit you! (HP: {self.player.health})")
                if self.player.health <= 0:
                    self.game_over = True
                    self.add_message("YOU DIED!")

        # Wave system
        if len(self.enemies) == 0:
            self.wave += 1
            self.spawn_enemies(self.wave + 2)
            self.spawn_weapons(1)
            self.player.traps += 1
            self.add_message(f"Wave {self.wave} incoming!")

    def render(self):
        self.stdscr.clear()
        
        # Draw borders
        for y in range(self.map_height):
            for x in range(self.map_width):
                if x == 0 or y == 0 or x == self.map_width - 1 or y == self.map_height - 1:
                    self.stdscr.addch(y, x, '#', curses.color_pair(0))
                else:
                    self.stdscr.addch(y, x, '.', curses.color_pair(0))
        
        # Draw weapons
        for weapon in self.weapons:
            weapon.draw(self.stdscr)
        
        # Draw traps
        for trap in self.traps:
            trap.draw(self.stdscr)
        
        # Draw enemies
        for enemy in self.enemies:
            enemy.draw(self.stdscr)
        
        # Draw player
        self.player.draw(self.stdscr)
        
        # UI
        status = f"HP: {self.player.health} | Wave: {self.wave} | Score: {self.score} | Weapons: {self.player.weapons[-1]} | Traps: {self.player.traps}"
        self.stdscr.addstr(self.map_height, 0, status, curses.color_pair(1))
        
        # Messages
        for i, message in enumerate(self.message_log):
            self.stdscr.addstr(self.map_height + 2 + i, 0, message, curses.color_pair(4))
        
        if self.game_over:
            self.stdscr.addstr(self.map_height + 1, 0, "GAME OVER! Press 'q' to quit.", curses.color_pair(2))
        
        self.stdscr.refresh()

    def run(self):
        while self.running:
            self.handle_input()
            self.update()
            self.render()
            time.sleep(0.1)

def main(stdscr):
    curses.curs_set(0)
    stdscr.keypad(True)
    stdscr.timeout(100)
    
    game = Game(stdscr)
    game.add_message("Welcome to DUNGEON STAY!")
    game.add_message("Arrow keys: Move | 'a': Attack | 't': Place Trap")
    game.add_message("Survive as long as you can!")
    game.run()

if __name__ == "__main__":
    curses.wrapper(main)