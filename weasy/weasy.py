import sys
import zlib
import re

def extract_zlib_streams(pdf_path):
    try:
        with open(pdf_path, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"❌ File not found: {pdf_path}")
        return

    streams = []
    for match in re.finditer(rb'>>\s*stream\s*\r?\n', data):
        stream_start = match.end()
        
        # Look ahead for the endstream
        stream_end = data.find(b'endstream', stream_start)
        if stream_end == -1:
            continue

        stream_data = data[stream_start:stream_end].strip()

        # Try to decompress
        try:
            decompressed = zlib.decompress(stream_data)
            streams.append(decompressed)
        except zlib.error:
            continue

    if not streams:
        print("❌ No valid zlib-compressed streams found.")
        return

    print(f"✅ Extracted {len(streams)} compressed stream(s).\n")
    for i, stream in enumerate(streams):
        print(f"--- Stream #{i+1} ---")
        try:
            print(stream.decode('utf-8'))
        except UnicodeDecodeError:
            print("⚠️ Could not decode stream as UTF-8.")
        print()

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python weasy.py <PDF_FILE>")
    else:
        extract_zlib_streams(sys.argv[1])
