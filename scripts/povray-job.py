#!/usr/bin/env python3

import os
import redis
import argparse
import uuid

# Configuration
REDIS_HOST = os.getenv("REDIS_HOST", "localhost") 
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
STREAM_NAME = os.getenv("QUEUE_NAME", "povray_jobs")

def connect_to_redis():
    try:
        r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
        r.ping() # Test connection
        return r
    except redis.ConnectionError as e:
        print(f"[!] Could not connect to Redis at {REDIS_HOST}:{REDIS_PORT}: {e}")
        exit(1)

def submit_jobs(scene_file, start_frame, end_frame, width, height, fps, crf):
    r = connect_to_redis()

    # Create a unique ID for this specific animation sequence
    render_id = f"{str(uuid.uuid4())[:8]}"
    total_frames = end_frame - start_frame + 1

    print(f"[*] Submitting {total_frames} jobs to stream '{STREAM_NAME}' for sequence '{render_id}'...")
    print(f"[*] Video Settings -> Resolution: {width}x{height}, FPS: {fps}, Quality (CRF): {crf}")

    # Push a job for each frame into the Redis stream
    for frame in range(start_frame, end_frame + 1):
        job_data = {
            "render_id": render_id,
            "total_frames": str(total_frames),
            "frame": str(frame),
            "start_frame": str(start_frame),
            "end_frame": str(end_frame),
            "width": str(width),
            "height": str(height),
            "fps": str(fps),
            "crf": str(crf),
            "scene_file": scene_file,
        }
        
        job_id = r.xadd(STREAM_NAME, job_data)
        print(f"[+] Submitted frame {frame} of ({start_frame}-{end_frame}) -> Job ID: {job_id}")

    print("[*] All jobs submitted successfully!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Submit POV-Ray rendering jobs to Redis.")
    parser.add_argument("scene_file", help="The .pov scene file (without absolute path)")
    parser.add_argument("--start", type=int, default=1, help="Start frame (default: 1)")
    parser.add_argument("--end", type=int, default=100, help="End frame (default: 100)")
    parser.add_argument("--width", type=int, default=800, help="Image width (default: 800)")
    parser.add_argument("--height", type=int, default=600, help="Image height (default: 600)")
    
    # New FFmpeg settings
    parser.add_argument("--fps", type=int, default=30, help="FFmpeg output framerate (default: 30)")
    parser.add_argument("--crf", type=int, default=23, help="FFmpeg video quality CRF (0-51, default: 23, lower is better)")
    
    args = parser.parse_args()

    submit_jobs(
        scene_file=args.scene_file,
        start_frame=args.start,
        end_frame=args.end,
        width=args.width,
        height=args.height,
        fps=args.fps,
        crf=args.crf
    )
