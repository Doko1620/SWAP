Project Overview

SWAP (Smart Wardrobe Advisor and Planner) is a mobile-based application designed to address two major modern challenges:
1. Environmental impact of fast fashion
2. Daily choice fatigue caused by overcrowded wardrobes

By integrating computer vision, machine learning and sustainability analytics SWAP digitizes users’ wardrobes, provides intelligent outfit recommendations and visualizes the environmental impact of clothing consumption. The system encourages mindful fashion behavior by helping users make better use of what they already own.

Objectives

1. Digitize personal wardrobes using image-based clothing classification
2. Reduce outfit decision fatigue through visualized outfit recommendations
3. Increase sustainability awareness via estimated wardrobe carbon footprint
4. Deploy an efficient deep learning model suitable for real-time mobile inference

Key Features

1. Automated Clothing Detection
Classifies clothing images into:
- Shirt / Tops
- Pants
- Shoes
- Headwear

2. Smart Wardrobe Management
- Store, view, filter, and delete wardrobe items

3. Outfit Recommendation Engine
- Mix-and-match outfit combinations
- Randomized outfit generation to reduce repetitive choices

4. Sustainability Tracking
- Estimated carbon footprint per clothing category
- Overall wardrobe sustainability score
- Educational sustainability insights (capsule wardrobe concept)

Machine Learning Model

Model Architecture: EfficientNetV2-B0
Framework: TensorFlow → TensorFlow Lite
Dataset Size: ~10,000 images
Categories: 4 clothing classes
Image Size: 224 × 224

Model Performance

5-Fold Stratified Cross Validation
Mean Accuracy: ~99.1%
Precision: 0.9993
Recall: 0.9995
F1-Score: 0.9994

Future Enhancements

- Expand clothing categories and attribute detection
- Material-based carbon footprint estimation
- Personalized capsule wardrobe generation
- Cloud-based analytics dashboard
- Larger-scale user evaluation