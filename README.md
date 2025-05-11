✅ Project Name: Finance Tracker


🔍 Overview:
A smart finance tracking app that manages income, expenses, goals, and reminders (like loans, rent, and fees). It provides suggestions using an ML model and integrates Gemini AI for finance-related queries.

🛠️ Core Features:
Income & Expense Tracking: Records all financial transactions.

Goals & Reminders: Set and track savings goals, bill reminders (e.g., loan, rent, fees).

Firebase Integration:

Authentication: Secure user login and sign-up.

Firestore: Cloud storage for user data (transactions, goals, etc).

ML-based Description Categorization:

Example: "Starbucks = $5" is auto-classified under Food and Beverage.

Model hosted locally via FastAPI due to server hosting cost limits.

AI Integration:

Google Gemini is integrated for answering finance-related questions quickly within the app.



🧠 Machine Learning Model (External Repo - Finance Tracker Models):
Receives the transaction description and amount.

Predicts the category (like Food, Travel, Rent, etc.).

Hosted locally using FastAPI (not cloud-hosted due to cost).



📱 App Tech Stack:
Frontend: Flutter

Backend: Firebase (Auth + Firestore)

ML API: FastAPI (Python) and modfied with TFLITE

AI Assistant: Google Gemini
