"""
Test script to verify .gitignore is working correctly.
This script creates test files that should be ignored by Git.
"""

import os
import subprocess
import sys
from pathlib import Path


def create_test_files():
    """Create test files that should be ignored"""
    print("Creating test files that should be ignored by Git...\n")

    test_files = [
        # Python cache
        "backend/app/__pycache__/test.pyc",
        "backend/app/test.py[cod]",

        # Environment files
        "backend/.env.test",
        "backend/.env.local",

        # Database files
        "backend/test.db",
        "backend/test.sqlite",

        # Log files
        "backend/test.log",
        "backend/app/debug.log",

        # IDE files
        ".vscode/settings.json",
        ".idea/workspace.xml",
        ".DS_Store",

        # Temporary files
        "backend/temp.tmp",
        "backend/backup.bak",
    ]

    created_files = []

    for file_path in test_files:
        try:
            # Create parent directories if they don't exist
            Path(file_path).parent.mkdir(parents=True, exist_ok=True)

            # Create the file
            with open(file_path, 'w') as f:
                f.write("This is a test file that should be ignored by Git")

            created_files.append(file_path)
            print(f"✅ Created: {file_path}")
        except Exception as e:
            print(f"❌ Failed to create {file_path}: {e}")

    return created_files


def check_git_status(test_files):
    """Check if test files are ignored by Git"""
    print("\n" + "=" * 60)
    print("Checking Git status...")
    print("=" * 60 + "\n")

    try:
        # Run git status --porcelain to get parseable output
        result = subprocess.run(
            ['git', 'status', '--porcelain'],
            capture_output=True,
            text=True,
            check=True
        )

        tracked_files = result.stdout.strip().split('\n') if result.stdout.strip() else []

        # Check if any test files appear in git status
        ignored_correctly = []
        not_ignored = []

        for test_file in test_files:
            # Check if this file appears in git status output
            is_tracked = any(test_file in line for line in tracked_files)

            if is_tracked:
                not_ignored.append(test_file)
            else:
                ignored_correctly.append(test_file)

        # Print results
        if ignored_correctly:
            print("✅ FILES CORRECTLY IGNORED:")
            for file in ignored_correctly:
                print(f"   ✓ {file}")

        if not_ignored:
            print("\n❌ FILES NOT IGNORED (ERROR):")
            for file in not_ignored:
                print(f"   ✗ {file}")
            print("\n⚠️  These files should be in .gitignore but are being tracked!")

        # Summary
        print("\n" + "=" * 60)
        print(f"SUMMARY: {len(ignored_correctly)}/{len(test_files)} files correctly ignored")
        print("=" * 60)

        return len(not_ignored) == 0

    except subprocess.CalledProcessError as e:
        print(f"❌ Error running git command: {e}")
        print("Make sure you're in a Git repository")
        return False
    except FileNotFoundError:
        print("❌ Git is not installed or not in PATH")
        return False


def cleanup_test_files(test_files):
    """Remove test files"""
    print("\n" + "=" * 60)
    print("Cleaning up test files...")
    print("=" * 60 + "\n")

    for file_path in test_files:
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                print(f"🗑️  Removed: {file_path}")

            # Remove empty directories
            parent = Path(file_path).parent
            if parent.exists() and not any(parent.iterdir()):
                parent.rmdir()
                print(f"🗑️  Removed empty directory: {parent}")

        except Exception as e:
            print(f"⚠️  Failed to remove {file_path}: {e}")


def main():
    """Main test function"""
    print("=" * 60)
    print("GITIGNORE VALIDATION TEST")
    print("=" * 60 + "\n")

    # Check if we're in a git repository
    if not os.path.exists('.git'):
        print("❌ This is not a Git repository!")
        print("Run 'git init' first before testing .gitignore")
        return False

    # Check if .gitignore exists
    if not os.path.exists('.gitignore'):
        print("❌ .gitignore file not found!")
        print("Please create .gitignore file first")
        return False

    print("✅ Found .gitignore file")
    print("✅ Git repository detected\n")

    # Create test files
    test_files = create_test_files()

    # Check git status
    success = check_git_status(test_files)

    # Cleanup
    cleanup_test_files(test_files)

    # Final result
    print("\n" + "=" * 60)
    if success:
        print("✅ SUCCESS: .gitignore is working correctly!")
    else:
        print("❌ FAILURE: Some files are not being ignored")
        print("Please check your .gitignore configuration")
    print("=" * 60)

    return success


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)