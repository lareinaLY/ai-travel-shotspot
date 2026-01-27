"""
Test script to verify .gitignore is working correctly.
Updated for full-stack project: Python backend + iOS frontend.
"""

import os
import subprocess
import sys
from pathlib import Path


def create_test_files():
    """Create test files that should be ignored"""
    print("Creating test files that should be ignored by Git...\n")

    test_files = [
        # === Python Backend Files ===
        # Python cache
        "backend/app/__pycache__/test.pyc",
        "backend/app/__pycache__/main.cpython-311.pyc",
        "backend/app/__pycache__/database.cpython-311.pyo",
        
        # Environment files
        "backend/.env.test",
        "backend/.env.local",
        "backend/.env.development",
        
        # Database files
        "backend/test.db",
        "backend/test.sqlite",
        "backend/test.sqlite3",
        
        # Log files
        "backend/test.log",
        "backend/app/debug.log",
        "backend/error.log",
        
        # === iOS/Xcode Files ===
        # Xcode user data (most common issue)
        "ios/ShotSpotFinder/ShotSpotFinder.xcodeproj/xcuserdata/testuser.xcuserdatad/UserInterfaceState.xcuserstate",
        "ios/ShotSpotFinder/ShotSpotFinder.xcodeproj/xcuserdata/testuser.xcuserdatad/xcschemes/xcschememanagement.plist",
        "ios/ShotSpotFinder/ShotSpotFinder.xcodeproj/project.xcworkspace/xcuserdata/testuser.xcuserdatad/UserInterfaceState.xcuserstate",
        
        # Xcode build files
        "ios/ShotSpotFinder/build/test.o",
        "ios/ShotSpotFinder/DerivedData/test.log",
        
        # === IDE/Editor Files ===
        ".vscode/settings.json",
        ".idea/workspace.xml",
        
        # === OS Files ===
        ".DS_Store",
        "backend/.DS_Store",
        "ios/.DS_Store",
        
        # === Temporary Files ===
        "backend/temp.tmp",
        "backend/backup.bak",
        "test.swp",
    ]

    created_files = []

    for file_path in test_files:
        try:
            Path(file_path).parent.mkdir(parents=True, exist_ok=True)
            with open(file_path, 'w') as f:
                f.write("Test file - should be ignored by Git")
            created_files.append(file_path)
            print(f"✅ Created: {file_path}")
        except Exception as e:
            print(f"❌ Failed to create {file_path}: {e}")

    return created_files


def check_git_status(test_files):
    """Check if test files are ignored by Git"""
    print("\n" + "=" * 70)
    print("Checking Git status...")
    print("=" * 70 + "\n")

    try:
        result = subprocess.run(
            ['git', 'status', '--porcelain'],
            capture_output=True,
            text=True,
            check=True
        )

        tracked_files = result.stdout.strip().split('\n') if result.stdout.strip() else []

        # Categorize files
        ignored_correctly = []
        not_ignored = []

        for test_file in test_files:
            is_tracked = any(test_file in line for line in tracked_files)
            if is_tracked:
                not_ignored.append(test_file)
            else:
                ignored_correctly.append(test_file)

        # Print categorized results
        if ignored_correctly:
            print("✅ FILES CORRECTLY IGNORED:")
            
            # Group by category
            backend_files = [f for f in ignored_correctly if f.startswith('backend/')]
            ios_files = [f for f in ignored_correctly if f.startswith('ios/')]
            other_files = [f for f in ignored_correctly if not f.startswith(('backend/', 'ios/'))]
            
            if backend_files:
                print("\n  📦 Backend Files:")
                for file in backend_files:
                    print(f"     ✓ {file}")
            
            if ios_files:
                print("\n  📱 iOS/Xcode Files:")
                for file in ios_files:
                    print(f"     ✓ {file}")
            
            if other_files:
                print("\n  🔧 Other Files:")
                for file in other_files:
                    print(f"     ✓ {file}")

        if not_ignored:
            print("\n❌ FILES NOT IGNORED (ERROR):")
            for file in not_ignored:
                print(f"   ✗ {file}")
            print("\n⚠️  These files should be in .gitignore but are being tracked!")

        # Summary
        print("\n" + "=" * 70)
        print(f"SUMMARY: {len(ignored_correctly)}/{len(test_files)} files correctly ignored")
        print("=" * 70)

        return len(not_ignored) == 0

    except subprocess.CalledProcessError as e:
        print(f"❌ Error running git command: {e}")
        return False
    except FileNotFoundError:
        print("❌ Git is not installed or not in PATH")
        return False


def cleanup_test_files(test_files):
    """Remove test files and empty directories"""
    print("\n" + "=" * 70)
    print("Cleaning up test files...")
    print("=" * 70 + "\n")

    cleaned_dirs = set()

    for file_path in test_files:
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                print(f"🗑️  Removed: {file_path}")
                
                # Track parent directory for cleanup
                parent = Path(file_path).parent
                cleaned_dirs.add(parent)
                
        except Exception as e:
            print(f"⚠️  Failed to remove {file_path}: {e}")

    # Remove empty directories
    for dir_path in sorted(cleaned_dirs, key=lambda x: len(str(x)), reverse=True):
        try:
            if dir_path.exists() and not any(dir_path.iterdir()):
                dir_path.rmdir()
                print(f"🗑️  Removed empty directory: {dir_path}")
        except Exception:
            pass


def main():
    """Main test function"""
    print("=" * 70)
    print("GITIGNORE VALIDATION TEST - Full-Stack Project")
    print("Testing: Python Backend + iOS Frontend")
    print("=" * 70 + "\n")

    # Check prerequisites
    if not os.path.exists('.git'):
        print("❌ This is not a Git repository!")
        print("Run 'git init' first before testing .gitignore")
        return False

    if not os.path.exists('.gitignore'):
        print("❌ .gitignore file not found!")
        print("Please create .gitignore file first")
        return False

    print("✅ Found .gitignore file")
    print("✅ Git repository detected\n")

    # Run tests
    test_files = create_test_files()
    success = check_git_status(test_files)
    cleanup_test_files(test_files)

    # Final result
    print("\n" + "=" * 70)
    if success:
        print("✅ SUCCESS: .gitignore is working correctly!")
        print("   Both Python and iOS files are properly protected.")
    else:
        print("❌ FAILURE: Some files are not being ignored")
        print("   Please check your .gitignore configuration")
    print("=" * 70)

    return success


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)