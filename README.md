# 📚 Library Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![React](https://img.shields.io/badge/React-18.x-61DAFB.svg?logo=react)](https://reactjs.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.x-4479A1.svg?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![TailwindCSS](https://img.shields.io/badge/Tailwind-3.x-38B2AC.svg?logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)

A comprehensive library management system with an interactive database visualization tool, designed to efficiently manage books, patrons, loans, and library operations.

![image](https://github.com/user-attachments/assets/a833dc66-7921-4db1-b697-9866fd2e39cf)

![image](https://github.com/user-attachments/assets/9711d724-1f98-4e21-9ae6-7b545726df0f)


## 🌟 Features

- *📊 Interactive Database Visualization:* Explore the database schema, relationships, and workflows visually
- *📝 Comprehensive Book Management:* Track inventory, locations, and availability
- *👥 Member Management:* Handle registrations, renewals, and membership status
- *📋 Loan Tracking:* Process checkouts, returns, and manage overdue items
- *🔍 Advanced Search Capabilities:* Find books by various criteria (author, category, availability)
- *⏱ Reservation System:* Allow members to reserve books that are currently checked out
- *📅 Event Management:* Schedule and track library events and attendees
- *💰 Fine Management:* Calculate and process late return fees

## 🖥 Technology Stack

- *Frontend:* React with TypeScript, Tailwind CSS
- *Backend:* MySQL Database
- *Database Features:* Stored Procedures, Triggers, Views

## 📋 Database Schema

The system includes the following core tables:
- Books
- Authors
- Publishers
- Categories
- Members
- Staff
- Loans
- Reservations
- Fines
- Events

## 🚀 Getting Started

### Prerequisites

- Node.js (v14+)
- MySQL (v8+)
- npm or yarn

### Installation

1. *Clone the repository*
   ```bash
   git clone https://github.com/AMMU-N-RAJ/Library_Management_System.git
   cd Library_Management_System
   ```

2. *Set up the database*
   ```bash
   mysql -u your_username -p < library-management-sql.sql
   ```

3. *Install dependencies and run the application*
   ```bash
   npm install -g serve
   serve
   ```
   *or with python:*
   
   ```bash
   python http.server 3000
   ```

4. *Access the application*
   - Open your browser and navigate to http://localhost:3000
     
![image](https://github.com/user-attachments/assets/6f65303c-4ca6-4fd1-8b93-875151137da3)

## 📊 Database Visualization Tool

The system includes an interactive visualization tool that allows you to:

- Explore the database schema visually
- View table relationships and details
- Understand stored procedures and triggers
- Visualize common library workflows

## 🧰 Key Database Operations

The system implements several key stored procedures:

- issue_book: Process book checkouts
- return_book: Handle book returns and calculate fines
- renew_loan: Extend loan periods
- search_books: Find books matching various criteria
- add_book: Add new books to the library database

## 📸 Screenshots
![image](https://github.com/user-attachments/assets/fc6733d2-d260-43ea-8ec0-481652117024)
![image](https://github.com/user-attachments/assets/a150bb29-aeff-4638-b06f-091db5e45241)

![image](https://github.com/user-attachments/assets/954c264f-cd14-456a-b421-21f0cb8c55da)
![image](https://github.com/user-attachments/assets/e2559773-cd2a-4cc2-95c7-3c898b3e0fd6)
![image](https://github.com/user-attachments/assets/75d9b0e0-00f0-4567-9b55-e3c234ecc071)
![image](https://github.com/user-attachments/assets/cc6a64bc-161e-4c3c-9825-116d77bf900f)
![image](https://github.com/user-attachments/assets/88b9fe1f-0913-4ee1-a268-2fe7eac7ff2a)


## 🏗 Project Structure


Library_Management_System/
├── library-management-sql.sql    # Database schema and sample data
├── library-system-visualization.tsx  # React component for visualization
├── view.sql                      # SQL helper queries
├── README.md                     # This file
└── ...


## 🔧 Customization

- Modify library-management-sql.sql to adjust the database schema
- Update business rules in stored procedures and triggers
- Customize the UI in the TSX files

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (git checkout -b feature/amazing-feature)
3. Commit your changes (git commit -m 'Add some amazing feature')
4. Push to the branch (git push origin feature/amazing-feature)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - click [License](https://github.com/AMMU-N-RAJ/Library_Mangement_System/blob/main/LICENSE)


