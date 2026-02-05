"""
Test script for CLIP aesthetic scorer.
Validates the scoring system with sample images.
"""

from app.services.aesthetic_scorer import calculate_aesthetic_score
import os

def test_scoring():
    """Test CLIP scoring on uploaded images"""
    
    # Find test images
    upload_dir = "uploads/photos"
    
    if not os.path.exists(upload_dir):
        print("No upload directory found")
        return
    
    images = [f for f in os.listdir(upload_dir) if f.endswith(('.jpg', '.jpeg', '.png'))]
    
    if not images:
        print("No images found in uploads/photos")
        return
    
    print(f"Testing CLIP scoring on {len(images)} images...\n")
    print("=" * 70)
    
    for img_file in images[:5]:  # Test first 5 images
        img_path = os.path.join(upload_dir, img_file)
        
        print(f"\nImage: {img_file}")
        print("-" * 70)
        
        try:
            score, breakdown = calculate_aesthetic_score(img_path, category="landscape")
            
            print(f"Aesthetic Score: {score:.2f}/100")
            print(f"\nBreakdown:")
            for dimension, value in breakdown.items():
                if dimension != "error" and dimension != "note":
                    if isinstance(value, (int, float)):
                        print(f"  {dimension:20s}: {value:.2f}")
                    else:
                        print(f"  {dimension:20s}: {value}")
                        
        except Exception as e:
            print(f"Error: {e}")
        
        print("=" * 70)

if __name__ == "__main__":
    test_scoring()