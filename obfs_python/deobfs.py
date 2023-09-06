import base64
import sys
import os

def encode_script(input_script_path, execute_script=False, output_script_path=None):
    try:
        with open(input_script_path, 'rb') as input_file:
            content_bytes = input_file.read()

        secret = base64.b64encode(content_bytes).decode('utf-8')

        if execute_script:
            try:
                exec(base64.b64decode(secret))
            except Exception as e:
                print(f"Error executing the script: {str(e)}")

        if output_script_path:
            with open(output_script_path, 'w') as output_file:
                output_file.write(secret)
            print(f"Script encoded and saved to {output_script_path}")

    except FileNotFoundError:
        print("Input script not found.")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python encode_script.py <input_script_path> [options1: --execute / options2 : --output=[path/script.py]]")
        sys.exit(1)

    input_script_path = sys.argv[1]

    execute_script = False
    output_script_path = None

    for arg in sys.argv[2:]:
        if arg == '--execute':
            execute_script = True
        elif arg.startswith('--output='):
            output_script_path = arg[len('--output='):]

    encode_script(input_script_path, execute_script, output_script_path)

if __name__ == "__main__":
    main()