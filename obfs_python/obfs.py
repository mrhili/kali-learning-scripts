import base64
import sys

# Check if the correct number of arguments are provided
if len(sys.argv) != 3:
    print("Usage: python obfs.py <input_script_path> <output_script_path>")
    sys.exit(1)

input_script_path = sys.argv[1]
output_script_path = sys.argv[2]

try:
    with open(input_script_path, 'rb') as input_file:
        content_bytes = input_file.read()

    secret = base64.b64encode(content_bytes)

    with open(output_script_path, 'wb') as output_file:
        output_file.write(secret)

    print(f"Script encoded and saved to {output_script_path}")
except FileNotFoundError:
    print("Input script not found.")
except Exception as e:
    print(f"An error occurred: {str(e)}")
