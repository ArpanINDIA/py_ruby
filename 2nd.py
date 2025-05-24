import curses
import random
import time

def main(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.timeout(100)
    stdscr.keypad(True)  # Enable keypad mode for arrow keys

    sh, sw = stdscr.getmaxyx()
    player_x = sw // 2
    score = 0
    star = [0, random.randint(1, sw-2)]

    while True:
        stdscr.clear()
        stdscr.border()

        # Draw player
        stdscr.addstr(sh-2, player_x, "A")

        # Draw star
        stdscr.addstr(star[0], star[1], "*")

        # Display score
        stdscr.addstr(0, 2, f" Score: {score} ")

        key = stdscr.getch()
        if key == curses.KEY_LEFT and player_x > 1:
            player_x -= 1
        elif key == curses.KEY_RIGHT and player_x < sw-2:
            player_x += 1
        elif key == ord('q'):
            break

        # Move star down
        star[0] += 1

        # Check for catch
        if star[0] == sh-2 and star[1] == player_x:
            score += 1
            star = [0, random.randint(1, sw-2)]
        elif star[0] > sh-2:
            stdscr.addstr(sh//2, sw//2-5, "Game Over!")
            stdscr.refresh()
            time.sleep(2)
            break

        stdscr.refresh()
        time.sleep(0.05)

if __name__ == "__main__":
    curses.wrapper(main)