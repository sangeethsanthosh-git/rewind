import os
import wave
import struct
import math
import random

SAMPLE_RATE = 44100

def create_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wf:
        wf.setnchannels(1)        # mono
        wf.setsampwidth(2)        # 16-bit
        wf.setframerate(SAMPLE_RATE)
        # Normalize and convert to 16-bit signed integers
        max_val = max(abs(s) for s in samples) if samples else 1.0
        if max_val == 0:
            max_val = 1.0
        scale = 32000.0 / max_val
        data = bytearray()
        for s in samples:
            val = int(max(min(s * scale, 32767), -32768))
            data.extend(struct.pack('<h', val))
        wf.writeframes(data)
    print(f"Generated {filename}: {len(samples)} samples ({len(samples)/SAMPLE_RATE*1000:.1f}ms)")

# 1. Play Button Clack (Solid mechanical lever engagement + switch transient)
def gen_play_clack():
    duration = 0.11 # 110 ms
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Initial transient strike (dual metal contact)
        strike1 = math.exp(-t * 220.0) * math.sin(2 * math.pi * 2100 * t)
        strike2 = math.exp(-t * 180.0) * math.sin(2 * math.pi * 3400 * t)
        # Low frequency chassis engagement thump
        chassis = math.exp(-t * 55.0) * math.sin(2 * math.pi * 180 * t)
        # Plastic catch click 12ms later
        catch = 0.0
        if t > 0.012:
            t_catch = t - 0.012
            catch = 0.6 * math.exp(-t_catch * 280.0) * math.sin(2 * math.pi * 2800 * t_catch)
        samples[i] = strike1 * 0.7 + strike2 * 0.4 + chassis * 0.8 + catch

    return samples

# 2. Pause / Stop Click (Clean mechanical latch release)
def gen_pause_click():
    duration = 0.065 # 65 ms
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        click = math.exp(-t * 190.0) * math.sin(2 * math.pi * 2600 * t)
        body = math.exp(-t * 90.0) * math.sin(2 * math.pi * 320 * t)
        snap = (random.random() * 2 - 1) * math.exp(-t * 350.0) * 0.3
        samples[i] = click * 0.8 + body * 0.4 + snap

    return samples

# 3. Skip / Rewind Click (Sharp physical detent tactile click)
def gen_skip_click():
    duration = 0.075 # 75 ms
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        c1 = math.exp(-t * 240.0) * math.sin(2 * math.pi * 3100 * t)
        c2 = math.exp(-t * 140.0) * math.sin(2 * math.pi * 1450 * t)
        samples[i] = c1 * 0.7 + c2 * 0.5

    return samples

# 4. Cassette Insertion (Plastic slide friction + seat lock)
def gen_cassette_insert():
    duration = 0.32 # 320 ms
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        # Phase 1: Slide friction across guides (0 to 180ms)
        if t < 0.18:
            envelope = math.sin(math.pi * (t / 0.18))
            noise = (random.random() * 2 - 1) * envelope * 0.25
            rail_hum = math.sin(2 * math.pi * 820 * t) * envelope * 0.15
            val = noise + rail_hum
        # Phase 2: Seating latch click (180ms to end)
        if t >= 0.18:
            t2 = t - 0.18
            seat1 = math.exp(-t2 * 110.0) * math.sin(2 * math.pi * 1250 * t2) * 0.9
            seat2 = math.exp(-t2 * 65.0) * math.sin(2 * math.pi * 220 * t2) * 0.7
            click = (random.random() * 2 - 1) * math.exp(-t2 * 250.0) * 0.3
            val += seat1 + seat2 + click
            
        samples[i] = val

    return samples

# 5. Cassette Eject (Spring pop + carriage slide out)
def gen_cassette_eject():
    duration = 0.26 # 260 ms
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Initial spring lever snap
        snap = math.exp(-t * 140.0) * math.sin(2 * math.pi * 1650 * t) * 0.9
        pop = math.exp(-t * 50.0) * math.sin(2 * math.pi * 140 * t) * 0.8
        # Sled motion friction (30ms to 200ms)
        friction = 0.0
        if 0.03 < t < 0.22:
            env = math.sin(math.pi * ((t - 0.03) / 0.19))
            friction = (random.random() * 2 - 1) * env * 0.2
        samples[i] = snap + pop + friction

    return samples

# 6. Door Latch (Sharp plastic/metal door snap)
def gen_door_latch():
    duration = 0.09 # 90 ms
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        snap1 = math.exp(-t * 220.0) * math.sin(2 * math.pi * 2400 * t)
        snap2 = math.exp(-t * 110.0) * math.sin(2 * math.pi * 1100 * t)
        body = math.exp(-t * 70.0) * math.sin(2 * math.pi * 280 * t)
        samples[i] = snap1 * 0.6 + snap2 * 0.4 + body * 0.5

    return samples

# 7. Motor Ambience (Subtle DC tape transport motor hum - seamlessly loopable)
def gen_motor_hum():
    duration = 0.8 # 800 ms loop
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # 110 Hz motor rotation fundamental + 220 Hz harmonic + subtle wow flutter
        wow = 1.0 + 0.02 * math.sin(2 * math.pi * 4.2 * t)
        f0 = 110.0 * wow
        hum1 = math.sin(2 * math.pi * f0 * t) * 0.35
        hum2 = math.sin(2 * math.pi * f0 * 2 * t) * 0.15
        hiss = (random.random() * 2 - 1) * 0.03
        samples[i] = (hum1 + hum2 + hiss) * 0.25 # Keep very gentle and subtle

    return samples

if __name__ == '__main__':
    out_dir = os.path.join(os.getcwd(), 'assets', 'sounds')
    create_wav(os.path.join(out_dir, 'btn_play_clack.wav'), gen_play_clack())
    create_wav(os.path.join(out_dir, 'btn_pause_click.wav'), gen_pause_click())
    create_wav(os.path.join(out_dir, 'btn_skip_click.wav'), gen_skip_click())
    create_wav(os.path.join(out_dir, 'cassette_insert.wav'), gen_cassette_insert())
    create_wav(os.path.join(out_dir, 'cassette_eject.wav'), gen_cassette_eject())
    create_wav(os.path.join(out_dir, 'door_latch.wav'), gen_door_latch())
    create_wav(os.path.join(out_dir, 'motor_hum.wav'), gen_motor_hum())
    print("All mechanical sound assets generated successfully!")
