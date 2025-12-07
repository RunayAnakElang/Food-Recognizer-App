

# Food Recognizer App — Dicoding Submission (Belajar Penerapan Machine Learning untuk Flutter)

This repository contains my Submission Project for the **Dicoding — Belajar Penerapan Machine Learning untuk Flutter** course.
The application integrates **Machine Learning**, **LiteRT**, **Firebase ML**, and **Generative AI (Gemini)** to recognize food from an image and display detailed information.

This project fulfills all required criteria across all assessment categories:
✔ Image Capture
✔ Machine Learning Integration
✔ Prediction & Detail Page
✔ External API + Gemini AI enhancement

---

## Key Features

###  1. Image Capture (Camera & Gallery)

* Take photos directly using **custom camera** (`camera` package)
* Pick image from gallery using `image_picker`
* Built-in **image cropping** for better ML accuracy
* Full permission handling & error handling

---

### 2. Food Classification with Machine Learning

* Uses **Food Classifier Model (TFLite)** provided by Dicoding
* Inference performed via **LiteRT** for optimized performance
* Supports inferencing via:

  * Photo input
  * Real-time (camera stream) — optional
* **Isolate** implementation to run inference on a background thread → prevents UI freeze
* Firebase ML supported (upload ML model to the cloud)

---

### 3. Prediction & Detail Page

After the ML model predicts the food, a dedicated detail page shows:

* 📷 Food image (user input)
* 🍛 Predicted food name
* 🎯 Confidence score
* 📚 Additional information retrieved from **TheMealDB API**:

  * Meal name
  * Meal image
  * Ingredients list
  * Measurement list
  * Cooking instructions

This section fulfills the *Skilled* criteria.

---

### 4. Nutrition Info with Gemini AI (Advanced)

The application also fetches **nutrition details** through **Gemini Generative AI**, including:

* Calories
* Carbohydrates
* Fats
* Fiber
* Protein

This allows the app to reach the **Advanced (4 pts)** criteria.

---

## App Screenshots

Pages implemented:

* Photo Picker Page  
  <img src="https://github.com/user-attachments/assets/664b305f-b615-49f0-9fb0-0b7b0c93dd51" width="250"/>
  <img src="https://github.com/user-attachments/assets/a5037dad-9478-4a60-ad09-ebb5d3a9c063" width="250"/>

* Analyze Page  
  <img src="https://github.com/user-attachments/assets/0bfbd1bd-fcf8-4d80-9803-0847ab995924" width="260"/>

* Result Page  
  <img src="https://github.com/user-attachments/assets/340b4b54-4440-4167-9870-26f745c7fa0d" width="250"/>
  <img src="https://github.com/user-attachments/assets/73cce5a1-6adf-4432-9c2d-5ee5b79be4be" width="250"/>

* Recipe Page  
  <img src="https://github.com/user-attachments/assets/06bc5d65-bcce-4d65-8707-0e5966fcab2b" width="260"/>


---

## 📥 How to Install and Run the Project

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/RunayAnakElang/Food-Recognizer-App.git
```

### 2️⃣ Navigate to the project folder

```bash
cd Food-Recognizer-App
```

### 3️⃣ Install all dependencies

```bash
flutter pub get
```

### 4️⃣ Run the application

```bash
flutter run
```

---

## Technologies Used

* **Flutter & Dart**
* **TensorFlow Lite (LiteRT)**
* **Image Picker**
* **Camera**
* **Isolate (background inference)**
* **MealDB API**
* **Google Gemini API (Generative AI)**
* **HTTP**

---

## Project Goals

This submission’s purpose is to:

✔ Integrate ML into Flutter apps
✔ Build a complete food recognition pipeline
✔ Use external APIs for data enrichment
✔ Display predictions & details with clean UI
✔ Implement AI-powered nutrition generation

