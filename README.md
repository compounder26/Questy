# Questy: Your AI-Powered Gamified Goal & Habit Tracker

**"Trust the AI"** - Let the AI guide you on your journey to better habits and achieved goals.

Questy is a mobile application that transforms habit formation and goal achievement into an engaging game. By integrating cutting-edge AI for task breakdown and verification, Questy makes staying on track both fun and rewarding. Earn points for completing tasks, customize your unique character, and unlock exciting rewards in the in-app shop!

---

## ✨ Core Features

* ### **Habit & Goal Management**
    * **Flexible Tracking:** Create and monitor both one-time goals and recurring habits.
    * **Recurring Options:** Supports daily and weekly habits to fit your routine.
    * **Visual Cues:** Color-coded habit types for quick identification and organization.
    * **Verified Progress:** Robust task completion verification system ensures accuracy.

* ### **Intelligent AI Integration**
    * **Goal Decomposition:** AI-powered breakdown of high-level goals into clear, actionable steps.
    * **Smart Scoring:** Automatic difficulty assessment and point assignment for each task.
    * **Dynamic Verification:** Task completion verified through detailed description analysis.
    * **Visual Confirmation:** Image-based verification option for physical tasks, bringing your achievements to life.

* ### **Engaging Character & Reward System**
    * **Personalized Avatar:** Customize your character with gender options (more coming soon!).
    * **Earn & Spend:** A point-based reward system fuels your progress.
    * **In-App Shop:** Purchase various rewards to enhance your Questy experience.
    * **Level Up:** Progress through levels as you accumulate points, showcasing your dedication.

---

## 🛠️ Technical Details

Questy is built with a strong and scalable architecture to ensure a smooth user experience.

* ### **Architecture**
    * **Clean Flutter:** Utilizes a clean Flutter architecture for maintainability and scalability.
    * **Provider Pattern:** Employs the Provider pattern for efficient state management.
    * **Local Persistence:** Leverages Hive database for fast and reliable local data storage.
    * **AI Backbone:** Seamlessly integrates with Google Cloud Vertex AI for intelligent functionalities.

* ### **Key Components**
    * **Models:** `Habit`, `HabitTask`, `User`, `Character`, `Reward`
    * **Providers:** `HabitProvider`, `CharacterProvider`
    * **Screens:** `HomeScreen`, `ProfileScreen`, `HistoryScreen`, `CharacterCustomizationScreen`
    * **Services:** `AIService` for robust integration with Large Language Models (LLMs).

---
