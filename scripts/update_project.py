import os
import re
import sys

def update_files_from_source(source_file_path="source_code_string.txt"):
    """
    Reads a source file containing multiple file contents demarcated by specific
    markers, extracts each file's path and content, and writes/overwrites
    the files in the current directory structure.

    Args:
        source_file_path (str): The path to the input text file.
    """
    print(f"--- Starting file update process from '{source_file_path}' ---")

    try:
        with open(source_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        print(f"Successfully read source file: '{source_file_path}'")
    except FileNotFoundError:
        print(f"Error: Source file not found at '{source_file_path}'")
        sys.exit(1)
    except IOError as e:
        print(f"Error reading source file '{source_file_path}': {e}")
        sys.exit(1)

    # Regex to find file blocks:
    # - Group 1: (.*?) captures the file path non-greedily
    # - Group 2: (.*?) captures the content between markers non-greedily,
    #            DOTALL allows '.' to match newlines.
    # - \1 ensures the END path matches the START path.
    # - Added optional leading/trailing whitespace handling around content
    pattern = re.compile(
        r'^--- START OF FILE (.*?) ---\n(.*?)\n^--- END OF FILE \1 ---',
        re.MULTILINE | re.DOTALL
    )

    matches = pattern.findall(content)

    if not matches:
        print("Warning: No file blocks found in the source file matching the expected format.")
        print("Format: --- START OF FILE path/file ---")
        print("        <content>")
        print("        --- END OF FILE path/file ---")
        return

    print(f"Found {len(matches)} file blocks to process.")
    files_updated = 0
    errors_occurred = 0

    for filepath, file_content in matches:
        # Clean up potential extra whitespace captured by DOTALL if needed,
        # though the pattern above is fairly specific.
        # file_content = file_content.strip() # Optional: uncomment if needed

        # Use os.path.normpath to handle mixed slashes (e.g., Windows vs Linux)
        # and remove redundant separators.
        normalized_filepath = os.path.normpath(filepath.strip())

        print(f"\nProcessing file: '{normalized_filepath}'...")

        try:
            # Get the directory part of the path
            directory = os.path.dirname(normalized_filepath)

            # If the directory is not empty (i.e., not the root), create it
            if directory:
                print(f"  Ensuring directory exists: '{directory}'")
                os.makedirs(directory, exist_ok=True)

            # Write the file (overwrite if exists)
            print(f"  Writing content to '{normalized_filepath}'...")
            with open(normalized_filepath, 'w', encoding='utf-8') as outfile:
                outfile.write(file_content)

            print(f"  Successfully updated: '{normalized_filepath}'")
            files_updated += 1

        except OSError as e:
            print(f"  Error creating directory or writing file '{normalized_filepath}': {e}")
            errors_occurred += 1
        except Exception as e:
            print(f"  An unexpected error occurred while processing '{normalized_filepath}': {e}")
            errors_occurred += 1

    print("\n--- File update process finished ---")
    print(f"Summary: {files_updated} files updated, {errors_occurred} errors.")

if __name__ == "__main__":
    # Assuming the script is run from the project root
    # and source_code_string.txt is in the same directory.
    update_files_from_source()