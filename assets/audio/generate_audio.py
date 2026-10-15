"""Regenerate deadlock_asta's original synthesized sound effects (Python stdlib only)."""

from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
TAU = math.tau
OUTPUT = Path(__file__).parent
RNG = random.Random(9)


def write(name, seconds, sample):
    frames = bytearray()
    total = int(RATE * seconds)
    for index in range(total):
        t = index / RATE
        value = max(-0.98, min(0.98, sample(t, seconds)))
        frames.extend(struct.pack("<h", int(value * 32767)))
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(frames)


def sine(t, frequency):
    return math.sin(TAU * t * frequency)


def envelope(t, seconds, attack=0.02):
    return min(1, t / attack) * min(1, max(0, seconds - t) / 0.1)


def room(t, _):
    # Integer periods over eight seconds make the mechanical drone seamless.
    return (sine(t, 55) * 0.25 + sine(t, 55.25) * 0.14 + sine(t, 110) * 0.07
            + sine(t, 27.5) * 0.2 + sine(t, 165) * 0.025) * (0.85 + 0.1 * sine(t, 0.25))


def step(t, seconds):
    return (RNG.uniform(-1, 1) * 0.2 + sine(t, 83) * 0.65) * math.exp(-t * 27) * envelope(t, seconds, 0.003)


def groan(t, seconds):
    carrier = sine(t + 0.001 * sine(t, 3), 67) + 0.35 * sine(t, 133) + 0.14 * sine(t, 211)
    return (carrier * 0.4 + RNG.uniform(-0.05, 0.05)) * math.sin(math.pi * t / seconds) ** 1.5


def door(t, seconds):
    motor = sine(t, 64) * 0.24 + sine(t, 130) * 0.14 + RNG.uniform(-0.14, 0.14)
    clunk = sine(t, 46) * 0.6 * math.exp(-max(0, t - 1.65) * 22) if t > 1.65 else 0
    beep = sine(t, 660) * 0.2 if t < 0.11 or 0.18 < t < 0.29 else 0
    return (motor * envelope(t, seconds, 0.14) + clunk + beep) * envelope(t, seconds, 0.003)


def heartbeat(t, seconds):
    first = math.exp(-t * 30) * sine(t, 50)
    second = math.exp(-(t - 0.16) * 32) * sine(t, 43) * 0.7 if t > 0.16 else 0
    return (first + second) * 0.8 * envelope(t, seconds, 0.003)


write("ambience", 8, room)
write("step", 0.22, step)
write("groan", 2.5, groan)
write("door", 2.1, door)
write("heartbeat", 0.5, heartbeat)
write("connect", 0.22, lambda t, d: sine(t, 440 if t < 0.11 else 660) * 0.25 * envelope(t, d, 0.005))
write("denied", 0.34, lambda t, d: (sine(t, 145) + sine(t, 153)) * 0.2 * envelope(t, d))
write("alert", 1.9, lambda t, d: (sine(t, 47) * 0.5 + RNG.uniform(-0.15, 0.15) * math.exp(-t * 7)) * envelope(t, d) * math.exp(-t * 1.4))
write("caught", 0.8, lambda t, d: (RNG.uniform(-0.2, 0.2) + sine(t, 57) * 0.5) * envelope(t, d, 0.006) * math.exp(-t * 4))
write("escape", 1.8, lambda t, d: (sine(t, 220) + sine(t, 330) + sine(t, 440)) * 0.13 * envelope(t, d, 0.2) * math.exp(-t * 1.2))
write("pistol", 0.45, lambda t, d: (RNG.uniform(-0.8, 0.8) * math.exp(-t * 38) + sine(t, 72) * 0.7 * math.exp(-t * 15)) * envelope(t, d, 0.001))
write("empty", 0.09, lambda t, d: RNG.uniform(-0.4, 0.4) * math.exp(-t * 90) * envelope(t, d, 0.001))
write("reload", 1.65, lambda t, d: RNG.uniform(-0.25, 0.25) * (math.exp(-t * 40) + (math.exp(-(t - 1.3) * 35) if t > 1.3 else 0)) * envelope(t, d, 0.002))
print("Generated 13 original mono PCM sound files.")
