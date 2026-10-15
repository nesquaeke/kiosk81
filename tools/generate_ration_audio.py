"""Rebuild original procedural foley prototypes; no downloaded audio or libraries.

Run from any directory: python3 tools/generate_ration_audio.py
These sounds are placeholders for future close-microphone paper/tool recordings.
"""
from array import array
from pathlib import Path
import math
import random
import sys
import wave

RATE = 44100
ROOT = Path(__file__).resolve().parents[1] / "assets/audio/ration"
SOUNDS = {
    "paper_pick": (0.38, "paper"),
    "paper_flip": (0.52, "flip"),
    "paper_place": (0.26, "place"),
    "snip": (0.16, "snip"),
    "stamp_down": (0.24, "stamp"),
    "stamp_lift": (0.18, "lift"),
    "coupon_drop": (0.32, "drop"),
    "drawer": (0.45, "drawer"),
    "package_meat_pick": (0.34, "butcher_pick"),
    "package_meat_place": (0.31, "butcher_place"),
    "package_sugar_pick": (0.39, "sugar_pick"),
    "package_sugar_place": (0.35, "sugar_place"),
    "package_soap_pick": (0.22, "sleeve_pick"),
    "package_soap_place": (0.24, "sleeve_place"),
}


def make_sound(name: str, seconds: float, kind: str) -> array:
    rng = random.Random(name)
    samples = array("h")
    low = 0.0
    slow = 0.0
    for index in range(round(seconds * RATE)):
        t = index / RATE
        noise = rng.uniform(-1, 1)
        low = 0.84 * low + 0.16 * noise
        slow = 0.97 * slow + 0.03 * noise
        attack = min(1.0, t / 0.006)
        tail = min(1.0, (seconds - t) / 0.02)
        envelope = attack * tail
        if kind in ("paper", "flip"):
            swell = math.sin(math.pi * t / seconds) ** 1.5
            crinkle = 0.35 + 0.65 * abs(math.sin(t * 52) * math.sin(t * 93))
            value = (low * 0.65 + noise * 0.09) * swell * crinkle
        elif kind == "stamp":
            value = 0.40 * math.sin(2 * math.pi * 92 * t) * math.exp(-t * 38)
            value += low * 0.45 * math.exp(-t * 45) + noise * 0.08 * math.exp(-t * 110)
        elif kind == "snip":
            value = noise * 0.16 * math.exp(-t * 45)
            value += math.sin(2 * math.pi * 2100 * t) * 0.10 * math.exp(-t * 80)
            value += low * 0.22 * math.exp(-((t - 0.055) / 0.028) ** 2)
        elif kind == "lift":
            value = (noise * 0.06 + low * 0.30) * math.sin(math.pi * t / seconds)
        elif kind == "drawer":
            value = slow * 0.8 * math.sin(math.pi * t / seconds)
            value += 0.18 * math.sin(2 * math.pi * 115 * t) * math.exp(-abs(t - 0.32) * 90)
        elif kind.startswith(("butcher", "sugar", "sleeve")):
            # Original synthesis: broad wrapping crinkles, granular bag rustle,
            # or a close dry sleeve scrape, with a distinct weighted contact.
            is_place = kind.endswith("place")
            swell = math.sin(math.pi * t / seconds)
            if kind.startswith("butcher"):
                value = (low * 0.48 + noise * 0.035) * swell
                value *= 0.4 + 0.6 * abs(math.sin(t * 43) * math.sin(t * 71))
                contact_hz, contact_gain = 74, 0.29
            elif kind.startswith("sugar"):
                grains = 0.3 + 0.7 * abs(math.sin(t * 157) * math.sin(t * 239))
                value = (noise * 0.055 + low * 0.31) * swell * grains
                contact_hz, contact_gain = 105, 0.19
            else:
                value = (noise * 0.024 + low * 0.16) * swell
                contact_hz, contact_gain = 225, 0.16
            if is_place:
                value += contact_gain * math.sin(2 * math.pi * contact_hz * t) * math.exp(-t * 36)
                value += low * 0.22 * math.exp(-t * 55)
        else:
            value = low * 0.35 * math.exp(-t * 18)
            value += 0.12 * math.sin(2 * math.pi * 180 * t) * math.exp(-t * 45)
        samples.append(round(max(-0.9, min(0.9, value * envelope)) * 32767))
    return samples


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    for name, (seconds, kind) in SOUNDS.items():
        samples = make_sound(name, seconds, kind)
        peak = max(abs(value) for value in samples) / 32767
        rms = math.sqrt(sum(value * value for value in samples) / len(samples)) / 32767
        if not 0.01 < peak < 0.9 or rms <= 0.001:
            raise ValueError(f"Invalid waveform: {name}, peak={peak}, RMS={rms}")
        if sys.byteorder != "little":
            samples.byteswap()
        with wave.open(str(ROOT / f"{name}.wav"), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(samples.tobytes())
        print(f"{name}: {seconds:.2f}s, peak={peak:.3f}, RMS={rms:.3f}")


if __name__ == "__main__":
    main()
