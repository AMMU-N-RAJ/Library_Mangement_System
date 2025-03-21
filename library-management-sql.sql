-- Library Management System Database Schema

-- Create database
CREATE DATABASE IF NOT EXISTS library_management;
USE library_management;

-- Create Authors table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Publishers table
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Categories table (for book genres/categories)
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Books table
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE,
    title VARCHAR(255) NOT NULL,
    publisher_id INT,
    publication_date DATE,
    edition VARCHAR(20),
    pages INT,
    language VARCHAR(30) DEFAULT 'English',
    description TEXT,
    shelf_location VARCHAR(50),
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1,
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL
);

-- Create Book_Authors table (many-to-many relationship between books and authors)
CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Create Book_Categories table (many-to-many relationship between books and categories)
CREATE TABLE book_categories (
    book_id INT,
    category_id INT,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- Create Members table (library patrons/members)
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    date_of_birth DATE,
    membership_date DATE DEFAULT (CURRENT_DATE),
    membership_expiry DATE,
    membership_status ENUM('Active', 'Expired', 'Suspended') DEFAULT 'Active',
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Staff table
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    position VARCHAR(50),
    hire_date DATE,
    salary DECIMAL(10, 2),
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255), -- In a real system, passwords should be properly hashed
    is_admin BOOLEAN DEFAULT FALSE,
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Loans table (for borrowing transactions)
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE DEFAULT (CURRENT_DATE),
    due_date DATE,
    return_date DATE,
    returned BOOLEAN DEFAULT FALSE,
    loan_status ENUM('Active', 'Returned', 'Overdue', 'Lost') DEFAULT 'Active',
    issued_by_staff_id INT,
    received_by_staff_id INT,
    fine_amount DECIMAL(10, 2) DEFAULT 0.00,
    fine_paid BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (issued_by_staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    FOREIGN KEY (received_by_staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Create Reservations table (for book reservations)
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    notes TEXT,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Create Fines table (could be consolidated with loans table, but separated for clarity)
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    member_id INT NOT NULL,
    fine_amount DECIMAL(10, 2) NOT NULL,
    reason TEXT,
    issue_date DATE DEFAULT (CURRENT_DATE),
    payment_date DATE,
    paid BOOLEAN DEFAULT FALSE,
    collected_by_staff_id INT,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (collected_by_staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Create Events table (for library events like book clubs, author visits, etc.)
CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE,
    start_time TIME,
    end_date DATE,
    end_time TIME,
    location VARCHAR(100),
    max_attendees INT,
    organized_by_staff_id INT,
    FOREIGN KEY (organized_by_staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Create Event_Attendees table (for tracking event attendance)
CREATE TABLE event_attendees (
    event_id INT,
    member_id INT,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    attended BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (event_id, member_id),
    FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Stored Procedures and Triggers

-- Trigger to update available_copies when a book is borrowed
DELIMITER //
CREATE TRIGGER after_loan_insert
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
    UPDATE books 
    SET available_copies = available_copies - 1 
    WHERE book_id = NEW.book_id;
END //
DELIMITER ;

-- Trigger to update available_copies when a book is returned
DELIMITER //
CREATE TRIGGER after_loan_update
AFTER UPDATE ON loans
FOR EACH ROW
BEGIN
    IF NEW.returned = TRUE AND OLD.returned = FALSE THEN
        UPDATE books 
        SET available_copies = available_copies + 1 
        WHERE book_id = NEW.book_id;
    END IF;
END //
DELIMITER ;

-- Procedure to issue a book to a member
DELIMITER //
CREATE PROCEDURE issue_book(
    IN p_book_id INT,
    IN p_member_id INT,
    IN p_staff_id INT,
    IN p_loan_days INT
)
BEGIN
    DECLARE v_available INT;
    DECLARE v_member_status VARCHAR(20);
    DECLARE v_due_date DATE;
    
    -- Check if book is available
    SELECT available_copies INTO v_available 
    FROM books 
    WHERE book_id = p_book_id;
    
    -- Check if member is active
    SELECT membership_status INTO v_member_status 
    FROM members 
    WHERE member_id = p_member_id;
    
    -- Calculate due date
    SET v_due_date = DATE_ADD(CURRENT_DATE, INTERVAL p_loan_days DAY);
    
    -- Issue book if available and member is active
    IF v_available > 0 AND v_member_status = 'Active' THEN
        INSERT INTO loans (
            book_id, 
            member_id, 
            loan_date, 
            due_date, 
            issued_by_staff_id
        ) VALUES (
            p_book_id, 
            p_member_id, 
            CURRENT_DATE, 
            v_due_date, 
            p_staff_id
        );
        
        SELECT 'Book issued successfully' AS message;
    ELSE
        IF v_available <= 0 THEN
            SELECT 'Book is not available for loan' AS message;
        ELSE
            SELECT 'Member is not active' AS message;
        END IF;
    END IF;
END //
DELIMITER ;

-- Procedure to return a book
DELIMITER //
CREATE PROCEDURE return_book(
    IN p_loan_id INT,
    IN p_staff_id INT
)
BEGIN
    DECLARE v_return_date DATE;
    DECLARE v_due_date DATE;
    DECLARE v_fine_amount DECIMAL(10, 2);
    DECLARE v_member_id INT;
    DECLARE v_book_id INT;
    
    -- Get loan details
    SELECT due_date, member_id, book_id INTO v_due_date, v_member_id, v_book_id
    FROM loans
    WHERE loan_id = p_loan_id AND returned = FALSE;
    
    SET v_return_date = CURRENT_DATE;
    
    -- Calculate fine if returned late (assuming $0.50 per day)
    IF v_return_date > v_due_date THEN
        SET v_fine_amount = DATEDIFF(v_return_date, v_due_date) * 0.50;
    ELSE
        SET v_fine_amount = 0;
    END IF;
    
    -- Update loan record
    UPDATE loans
    SET 
        return_date = v_return_date,
        returned = TRUE,
        loan_status = 'Returned',
        received_by_staff_id = p_staff_id,
        fine_amount = v_fine_amount
    WHERE loan_id = p_loan_id;
    
    -- Create fine record if there's a fine
    IF v_fine_amount > 0 THEN
        INSERT INTO fines (
            loan_id,
            member_id,
            fine_amount,
            reason,
            issue_date
        ) VALUES (
            p_loan_id,
            v_member_id,
            v_fine_amount,
            'Late return',
            v_return_date
        );
    END IF;
    
    SELECT 'Book returned successfully' AS message, 
           v_fine_amount AS fine_amount;
END //
DELIMITER ;

-- Procedure to renew a book loan
DELIMITER //
CREATE PROCEDURE renew_loan(
    IN p_loan_id INT,
    IN p_renewal_days INT
)
BEGIN
    DECLARE v_due_date DATE;
    DECLARE v_loan_status VARCHAR(20);
    DECLARE v_new_due_date DATE;
    
    -- Get current loan details
    SELECT due_date, loan_status INTO v_due_date, v_loan_status
    FROM loans
    WHERE loan_id = p_loan_id;
    
    -- Calculate new due date
    SET v_new_due_date = DATE_ADD(v_due_date, INTERVAL p_renewal_days DAY);
    
    -- Renew loan if it's active
    IF v_loan_status = 'Active' THEN
        UPDATE loans
        SET 
            due_date = v_new_due_date,
            notes = CONCAT(IFNULL(notes, ''), ' Renewed on ', CURRENT_DATE)
        WHERE loan_id = p_loan_id;
        
        SELECT 'Loan renewed successfully' AS message, 
               v_new_due_date AS new_due_date;
    ELSE
        SELECT 'Cannot renew loan. Current status: ' AS message, 
               v_loan_status AS status;
    END IF;
END //
DELIMITER ;

-- Procedure to add a new book
DELIMITER //
CREATE PROCEDURE add_book(
    IN p_isbn VARCHAR(20),
    IN p_title VARCHAR(255),
    IN p_publisher_id INT,
    IN p_publication_date DATE,
    IN p_edition VARCHAR(20),
    IN p_pages INT,
    IN p_language VARCHAR(30),
    IN p_description TEXT,
    IN p_shelf_location VARCHAR(50),
    IN p_total_copies INT,
    IN p_author_ids VARCHAR(255), -- Comma-separated list of author IDs
    IN p_category_ids VARCHAR(255) -- Comma-separated list of category IDs
)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_author_id INT;
    DECLARE v_category_id INT;
    DECLARE v_pos INT;
    DECLARE v_author_list VARCHAR(255);
    DECLARE v_category_list VARCHAR(255);
    
    -- Insert book record
    INSERT INTO books (
        isbn,
        title,
        publisher_id,
        publication_date,
        edition,
        pages,
        language,
        description,
        shelf_location,
        total_copies,
        available_copies
    ) VALUES (
        p_isbn,
        p_title,
        p_publisher_id,
        p_publication_date,
        p_edition,
        p_pages,
        p_language,
        p_description,
        p_shelf_location,
        p_total_copies,
        p_total_copies
    );
    
    SET v_book_id = LAST_INSERT_ID();
    
    -- Add author associations
    SET v_author_list = p_author_ids;
    
    WHILE LENGTH(v_author_list) > 0 DO
        SET v_pos = INSTR(v_author_list, ',');
        
        IF v_pos > 0 THEN
            SET v_author_id = TRIM(SUBSTRING(v_author_list, 1, v_pos - 1));
            SET v_author_list = SUBSTRING(v_author_list, v_pos + 1);
        ELSE
            SET v_author_id = TRIM(v_author_list);
            SET v_author_list = '';
        END IF;
        
        IF LENGTH(v_author_id) > 0 THEN
            INSERT INTO book_authors (book_id, author_id)
            VALUES (v_book_id, v_author_id);
        END IF;
    END WHILE;
    
    -- Add category associations
    SET v_category_list = p_category_ids;
    
    WHILE LENGTH(v_category_list) > 0 DO
        SET v_pos = INSTR(v_category_list, ',');
        
        IF v_pos > 0 THEN
            SET v_category_id = TRIM(SUBSTRING(v_category_list, 1, v_pos - 1));
            SET v_category_list = SUBSTRING(v_category_list, v_pos + 1);
        ELSE
            SET v_category_id = TRIM(v_category_list);
            SET v_category_list = '';
        END IF;
        
        IF LENGTH(v_category_id) > 0 THEN
            INSERT INTO book_categories (book_id, category_id)
            VALUES (v_book_id, v_category_id);
        END IF;
    END WHILE;
    
    SELECT 'Book added successfully with ID: ' AS message, 
           v_book_id AS book_id;
END //
DELIMITER ;

-- Function to calculate total fines for a member
DELIMITER //
CREATE FUNCTION get_member_total_fines(p_member_id INT) 
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE v_total_fines DECIMAL(10, 2);
    
    SELECT COALESCE(SUM(fine_amount), 0) INTO v_total_fines
    FROM fines
    WHERE member_id = p_member_id AND paid = FALSE;
    
    RETURN v_total_fines;
END //
DELIMITER ;

-- Procedure to generate overdue notices
DELIMITER //
CREATE PROCEDURE generate_overdue_notices()
BEGIN
    SELECT 
        l.loan_id,
        b.title AS book_title,
        CONCAT(m.first_name, ' ', m.last_name) AS member_name,
        m.email AS member_email,
        l.due_date,
        DATEDIFF(CURRENT_DATE, l.due_date) AS days_overdue,
        DATEDIFF(CURRENT_DATE, l.due_date) * 0.50 AS estimated_fine
    FROM loans l
    JOIN books b ON l.book_id = b.book_id
    JOIN members m ON l.member_id = m.member_id
    WHERE l.returned = FALSE 
      AND l.due_date < CURRENT_DATE
    ORDER BY days_overdue DESC;
END //
DELIMITER ;

-- Event to automatically update loan status for overdue books
DELIMITER //
CREATE EVENT update_overdue_loans
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE loans
    SET loan_status = 'Overdue'
    WHERE due_date < CURRENT_DATE 
      AND returned = FALSE 
      AND loan_status = 'Active';
END //
DELIMITER ;

-- Procedure to search books by various criteria
DELIMITER //
CREATE PROCEDURE search_books(
    IN p_title VARCHAR(255),
    IN p_author_name VARCHAR(100),
    IN p_category_name VARCHAR(50),
    IN p_publisher_name VARCHAR(100),
    IN p_available_only BOOLEAN
)
BEGIN
    SELECT 
        b.book_id,
        b.isbn,
        b.title,
        GROUP_CONCAT(DISTINCT CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
        GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS categories,
        p.name AS publisher,
        b.publication_date,
        b.edition,
        b.pages,
        b.language,
        b.shelf_location,
        b.total_copies,
        b.available_copies
    FROM books b
    LEFT JOIN book_authors ba ON b.book_id = ba.book_id
    LEFT JOIN authors a ON ba.author_id = a.author_id
    LEFT JOIN book_categories bc ON b.book_id = bc.book_id
    LEFT JOIN categories c ON bc.category_id = c.category_id
    LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
    WHERE 
        (p_title IS NULL OR b.title LIKE CONCAT('%', p_title, '%'))
        AND (p_author_name IS NULL OR CONCAT(a.first_name, ' ', a.last_name) LIKE CONCAT('%', p_author_name, '%'))
        AND (p_category_name IS NULL OR c.name LIKE CONCAT('%', p_category_name, '%'))
        AND (p_publisher_name IS NULL OR p.name LIKE CONCAT('%', p_publisher_name, '%'))
        AND (p_available_only = FALSE OR b.available_copies > 0)
    GROUP BY b.book_id
    ORDER BY b.title;
END //
DELIMITER ;

-- Procedure to get member borrowing history
DELIMITER //
CREATE PROCEDURE get_member_borrowing_history(
    IN p_member_id INT
)
BEGIN
    SELECT 
        l.loan_id,
        b.title AS book_title,
        CONCAT(a.first_name, ' ', a.last_name) AS author,
        l.loan_date,
        l.due_date,
        l.return_date,
        l.loan_status,
        l.fine_amount
    FROM loans l
    JOIN books b ON l.book_id = b.book_id
    JOIN book_authors ba ON b.book_id = ba.book_id
    JOIN authors a ON ba.author_id = a.author_id
    WHERE l.member_id = p_member_id
    ORDER BY l.loan_date DESC;
END //
DELIMITER ;

-- Procedure to get library statistics
DELIMITER //
CREATE PROCEDURE get_library_statistics()
BEGIN
    -- Total counts
    SELECT 
        (SELECT COUNT(*) FROM books) AS total_books,
        (SELECT SUM(total_copies) FROM books) AS total_book_copies,
        (SELECT COUNT(*) FROM members WHERE membership_status = 'Active') AS active_members,
        (SELECT COUNT(*) FROM loans WHERE returned = FALSE) AS active_loans,
        (SELECT COUNT(*) FROM reservations WHERE status = 'Pending') AS pending_reservations,
        (SELECT COUNT(*) FROM events WHERE end_date >= CURRENT_DATE) AS upcoming_events;
    
    -- Most popular books (most borrowed)
    SELECT 
        b.title,
        COUNT(l.loan_id) AS borrow_count
    FROM books b
    JOIN loans l ON b.book_id = l.book_id
    GROUP BY b.book_id
    ORDER BY borrow_count DESC
    LIMIT 10;
    
    -- Most active members (most books borrowed)
    SELECT 
        CONCAT(m.first_name, ' ', m.last_name) AS member_name,
        COUNT(l.loan_id) AS borrow_count
    FROM members m
    JOIN loans l ON m.member_id = l.member_id
    GROUP BY m.member_id
    ORDER BY borrow_count DESC
    LIMIT 10;
    
    -- Monthly loan statistics for the past year
    SELECT 
        DATE_FORMAT(loan_date, '%Y-%m') AS month,
        COUNT(*) AS loan_count
    FROM loans
    WHERE loan_date >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
    GROUP BY month
    ORDER BY month;
END //
DELIMITER ;

-- View for available books
CREATE VIEW vw_available_books AS
SELECT 
    b.book_id,
    b.isbn,
    b.title,
    GROUP_CONCAT(DISTINCT CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    p.name AS publisher,
    b.publication_date,
    GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS categories,
    b.shelf_location,
    b.available_copies
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
LEFT JOIN book_categories bc ON b.book_id = bc.book_id
LEFT JOIN categories c ON bc.category_id = c.category_id
WHERE b.available_copies > 0
GROUP BY b.book_id
ORDER BY b.title;

-- View for overdue loans
CREATE VIEW vw_overdue_loans AS
SELECT 
    l.loan_id,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURRENT_DATE, l.due_date) AS days_overdue,
    b.title AS book_title,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email AS member_email,
    m.phone AS member_phone,
    DATEDIFF(CURRENT_DATE, l.due_date) * 0.50 AS estimated_fine
FROM loans l
JOIN books b ON l.book_id = b.book_id
JOIN members m ON l.member_id = m.member_id
WHERE l.returned = FALSE AND l.due_date < CURRENT_DATE
ORDER BY days_overdue DESC;

-- View for book inventory
CREATE VIEW vw_book_inventory AS
SELECT 
    b.book_id,
    b.isbn,
    b.title,
    GROUP_CONCAT(DISTINCT CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    p.name AS publisher,
    b.publication_date,
    b.edition,
    b.language,
    GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS categories,
    b.shelf_location,
    b.total_copies,
    b.available_copies,
    (b.total_copies - b.available_copies) AS checked_out_copies
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
LEFT JOIN book_categories bc ON b.book_id = bc.book_id
LEFT JOIN categories c ON bc.category_id = c.category_id
GROUP BY b.book_id
ORDER BY b.title;

-- Sample Data Insertion

-- Insert Authors
INSERT INTO authors (first_name, last_name, birth_date, nationality, biography) VALUES 
('J.K.', 'Rowling', '1965-07-31', 'British', 'British author best known for the Harry Potter series'),
('George R.R.', 'Martin', '1948-09-20', 'American', 'American novelist and short-story writer, screenwriter, and television producer'),
('Jane', 'Austen', '1775-12-16', 'British', 'English novelist known primarily for six major novels'),
('Leo', 'Tolstoy', '1828-09-09', 'Russian', 'Russian writer who is regarded as one of the greatest authors of all time'),
('Agatha', 'Christie', '1890-09-15', 'British', 'English writer known for her 66 detective novels and 14 short story collections'),
('Stephen', 'King', '1947-09-21', 'American', 'American author of horror, supernatural fiction, suspense, and fantasy novels'),
('J.R.R.', 'Tolkien', '1892-01-03', 'British', 'English writer, poet, philologist, and academic'),
('Ernest', 'Hemingway', '1899-07-21', 'American', 'American novelist, short-story writer, and journalist'),
('Virginia', 'Woolf', '1882-01-25', 'British', 'English writer, considered one of the most important modernist 20th-century authors'),
('Gabriel', 'García Márquez', '1927-03-06', 'Colombian', 'Colombian novelist, short-story writer, screenwriter, and journalist');

-- Insert Publishers
INSERT INTO publishers (name, address, phone, email, website) VALUES 
('Penguin Random House', '1745 Broadway, New York, NY 10019, USA', '+1-212-782-9000', 'info@penguinrandomhouse.com', 'www.penguinrandomhouse.com'),
('HarperCollins', '195 Broadway, New York, NY 10007, USA', '+1-212-207-7000', 'info@harpercollins.com', 'www.harpercollins.com'),
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY 10020, USA', '+1-212-698-7000', 'info@simonandschuster.com', 'www.simonandschuster.com'),
('Macmillan Publishers', '120 Broadway, New York, NY 10271, USA', '+1-646-307-5151', 'info@macmillan.com', 'www.macmillan.com'),
('Oxford University Press', 'Great Clarendon Street, Oxford OX2 6DP, UK', '+44-1865-556767', 'info@oup.com', 'www.oup.com');

-- Insert Categories
INSERT INTO categories (name, description) VALUES 
('Fiction', 'Literature created from the imagination, not presented as fact, though it may be based on a true story or situation'),
('Fantasy', 'Speculative fiction set in a fictional universe, often inspired by myth and folklore'),
('Science Fiction', 'Fiction dealing with futuristic concepts such as advanced science and technology, space exploration, time travel, parallel universes, and extraterrestrial life'),
('Mystery', 'Fiction dealing with the solution of a crime or the unraveling of secrets'),
('Romance', 'Novels that focus on the relationship and romantic love between two people'),
('Thriller', 'Fiction characterized by fast pacing, frequent action, and resourceful heroes who must thwart the plans of more-powerful and better-equipped villains'),
('Biography', 'A detailed description or account of someone\'s life'),
('History', 'Books that focus on historical accounts or events'),
('Self-Help', 'Books written with the intention to instruct readers on solving personal problems'),
('Children\'s', 'Books written for and marketed to children');

-- Insert Books
INSERT INTO books (isbn, title, publisher_id, publication_date, edition, pages, language, description, shelf_location, total_copies, available_copies) VALUES 
('9780747532743', 'Harry Potter and the Philosopher\'s Stone', 1, '1997-06-26', '1st', 223, 'English', 'The first novel in the Harry Potter series', 'A1-01', 5, 5),
('9780261103573', 'The Lord of the Rings: The Fellowship of the Ring', 2, '1954-07-29', '1st', 423, 'English', 'The first volume of The Lord of the Rings trilogy', 'A1-02', 3, 3),
('9780553103540', 'A Game of Thrones', 3, '1996-08-01', '1st', 694, 'English', 'The first novel in A Song of Ice and Fire series', 'A1-03', 4, 4),
('9780141439518', 'Pride and Prejudice', 1, '1813-01-28', '3rd', 432, 'English', 'A romantic novel by Jane Austen', 'A2-01', 3, 3),
('9780451524935', '1984', 2, '1949-06-08', '2nd', 328, 'English', 'A dystopian novel by George Orwell', 'A2-02', 5, 5),
('9780061120084', 'To Kill a Mockingbird', 2, '1960-07-11', '1st', 281, 'English', 'A novel by Harper Lee', 'A2-03', 4, 4),
('9780307474278', 'The Shining', 3, '1977-01-28', '1st', 447, 'English', 'A horror novel by Stephen King', 'A3-01', 2, 2),
('9780679783268', 'Crime and Punishment', 4, '1866-01-01', '1st', 671, 'English', 'A novel by Fyodor Dostoevsky', 'A3-02', 2, 2),
('9780062315007', 'The Alchemist', 2, '1988-01-01', '1st', 197, 'English', 'A novel by Paulo Coelho', 'A3-03', 3, 3),
('9780743273565', 'The Great Gatsby', 3, '1925-04-10', '1st', 180, 'English', 'A novel by F. Scott Fitzgerald', 'A4-01', 3, 3);

-- Insert Book-Author Relationships
INSERT INTO book_authors (book_id, author_id) VALUES 
(1, 1), -- Harry Potter - J.K. Rowling
(2, 7), -- Fellowship of the Ring - J.R.R. Tolkien
(3, 2), -- Game of Thrones - George R.R. Martin
(4, 3), -- Pride and Prejudice - Jane Austen
(5, 9), -- 1984 - Virginia Woolf (for demonstration purposes)
(6, 8), -- To Kill a Mockingbird - Ernest Hemingway (for demonstration purposes)
(7, 6), -- The Shining - Stephen King
(8, 4), -- Crime and Punishment - Leo Tolstoy (for demonstration purposes)
(9, 10), -- The Alchemist - Gabriel García Márquez (for demonstration purposes)
(10, 8); -- The Great Gatsby - Ernest Hemingway (for demonstration purposes)

-- Insert Book-Category Relationships
INSERT INTO book_categories (book_id, category_id) VALUES 
(1, 1), (1, 2), -- Harry Potter - Fiction, Fantasy
(2, 1), (2, 2), -- Fellowship of the Ring - Fiction, Fantasy
(3, 1), (3, 2), -- Game of Thrones - Fiction, Fantasy
(4, 1), (4, 5), -- Pride and Prejudice - Fiction, Romance
(5, 1), (5, 3), -- 1984 - Fiction, Science Fiction
(6, 1), (6, 4), -- To Kill a Mockingbird - Fiction, Mystery
(7, 1), (7, 6), -- The Shining - Fiction, Thriller
(8, 1), (8, 4), -- Crime and Punishment - Fiction, Mystery
(9, 1), (9, 9), -- The Alchemist - Fiction, Self-Help
(10, 1), (10, 6); -- The Great Gatsby - Fiction, Thriller

-- Insert Members
INSERT INTO members (first_name, last_name, email, phone, address, date_of_birth, membership_date, membership_expiry, membership_status) VALUES 
('John', 'Smith', 'john.smith@email.com', '555-123-4567', '123 Main St, Anytown, ST 12345', '1985-03-15', '2023-01-10', '2024-01-10', 'Active'),
('Emily', 'Johnson', 'emily.johnson@email.com', '555-234-5678', '456 Oak Ave, Somewhere, ST 23456', '1990-07-22', '2023-02-15', '2024-02-15', 'Active'),
('Michael', 'Williams', 'michael.williams@email.com', '555-345-6789', '789 Pine Rd, Nowhere, ST 34567', '1978-11-05', '2023-03-20', '2024-03-20', 'Active'),
('Sarah', 'Brown', 'sarah.brown@email.com', '555-456-7890', '101 Elm Blvd, Anywhere, ST 45678', '1995-05-18', '2023-04-25', '2024-04-25', 'Active'),
('David', 'Jones', 'david.jones@email.com', '555-567-8901', '202 Maple Dr, Everywhere, ST 56789', '1982-09-30', '2023-01-05', '2023-07-05', 'Expired'),
('Jessica', 'Miller', 'jessica.miller@email.com', '555-678-9012', '303 Cedar Ln, Someplace, ST 67890', '1988-12-12', '2023-06-15', '2024-06-15', 'Active'),
('Robert', 'Davis', 'robert.davis@email.com', '555-789-0123', '404 Birch Ct, Otherplace, ST 78901', '1975-04-25', '2023-07-20', '2024-07-20', 'Active'),
('Jennifer', 'Garcia', 'jennifer.garcia@email.com', '555-890-1234', '505 Willow Way, Thisplace, ST 89012', '1992-08-08', '2023-08-25', '2024-08-25', 'Active'),
('William', 'Rodriguez', 'william.rodriguez@email.com', '555-901-2345', '606 Spruce Path, Thatplace, ST 90123', '1980-02-14', '2023-09-01', '2023-12-01', 'Suspended'),
('Lisa', 'Martinez', 'lisa.martinez@email.com', '555-012-3456', '707 Aspen Trail, Yourplace, ST 01234', '1993-06-27', '2023-10-05', '2024-10-05', 'Active');

-- Insert Staff
INSERT INTO staff (first_name, last_name, email, phone, address, position, hire_date, salary, username, password_hash, is_admin) VALUES 
('James', 'Wilson', 'james.wilson@library.com', '555-111-2222', '111 Library Ave, Booktown, ST 11111', 'Head Librarian', '2015-06-01', 65000.00, 'jwilson', 'hashed_password_1', TRUE),
('Mary', 'Taylor', 'mary.taylor@library.com', '555-222-3333', '222 Book St, Readville, ST 22222', 'Assistant Librarian', '2018-08-15', 45000.00, 'mtaylor', 'hashed_password_2', FALSE),
('Thomas', 'Anderson', 'thomas.anderson@library.com', '555-333-4444', '333 Page Rd, Literature, ST 33333', 'Cataloguer', '2020-03-10', 42000.00, 'tanderson', 'hashed_password_3', FALSE),
('Patricia', 'Thomas', 'patricia.thomas@library.com', '555-444-5555', '444 Chapter Dr, Bookland, ST 44444', 'Reference Librarian', '2019-11-20', 48000.00, 'pthomas', 'hashed_password_4', FALSE),
('Christopher', 'Jackson', 'christopher.jackson@library.com', '555-555-6666', '555 Novel Blvd, Storyville, ST 55555', 'IT Administrator', '2021-01-15', 52000.00, 'cjackson', 'hashed_password_5', TRUE);

-- Insert Loans
INSERT INTO loans (book_id, member_id, loan_date, due_date, return_date, returned, loan_status, issued_by_staff_id, received_by_staff_id, notes) VALUES 
(1, 1, '2023-06-01', '2023-06-15', '2023-06-14', TRUE, 'Returned', 1, 2, 'Returned on time'),
(2, 2, '2023-06-05', '2023-06-19', '2023-06-18', TRUE, 'Returned', 2, 3, 'Returned one day early'),
(3, 3, '2023-06-10', '2023-06-24', NULL, FALSE, 'Active', 3, NULL, NULL),
(4, 4, '2023-06-15', '2023-06-29', NULL, FALSE, 'Active', 1, NULL, NULL),
(5, 5, '2023-06-01', '2023-06-15', '2023-06-20', TRUE, 'Returned', 2, 2, 'Returned 5 days late'),
(6, 6, '2023-06-05', '2023-06-19', NULL, FALSE, 'Overdue', 3, NULL, 'Contacted member on 2023-06-20'),
(7, 7, '2023-06-20', '2023-07-04', NULL, FALSE, 'Active', 1, NULL, NULL),
(8, 8, '2023-06-25', '2023-07-09', NULL, FALSE, 'Active', 2, NULL, NULL),
(9, 1, '2023-06-15', '2023-06-29', '2023-06-28', TRUE, 'Returned', 3, 1, 'Member enjoyed the book'),
(10, 2, '2023-06-20', '2023-07-04', NULL, FALSE, 'Active', 1, NULL, NULL);

-- Insert Reservations
INSERT INTO reservations (book_id, member_id, reservation_date, expiry_date, status, notes) VALUES 
(1, 3, '2023-06-25', '2023-07-10', 'Pending', 'Next in queue'),
(2, 4, '2023-06-26', '2023-07-11', 'Pending', NULL),
(3, 5, '2023-06-27', '2023-07-12', 'Cancelled', 'Member cancelled on 2023-06-30'),
(4, 6, '2023-06-28', '2023-07-13', 'Pending', NULL),
(5, 7, '2023-06-29', '2023-07-14', 'Fulfilled', 'Book checked out on 2023-07-01');

-- Insert Fines
INSERT INTO fines (loan_id, member_id, fine_amount, reason, issue_date, payment_date, paid, collected_by_staff_id) VALUES 
(5, 5, 2.50, 'Late return - 5 days', '2023-06-20', '2023-06-22', TRUE, 2),
(6, 6, 5.00, 'Late return - 10 days', '2023-06-29', NULL, FALSE, NULL);

-- Insert Events
INSERT INTO events (title, description, start_date, start_time, end_date, end_time, location, max_attendees, organized_by_staff_id) VALUES 
('Summer Reading Kickoff', 'Join us to kickoff our summer reading program with games, prizes, and refreshments.', '2023-06-15', '14:00:00', '2023-06-15', '17:00:00', 'Main Library - Community Room', 50, 1),
('Author Meet & Greet', 'Meet local author Jane Doe as she discusses her new book.', '2023-06-20', '18:30:00', '2023-06-20', '20:00:00', 'Main Library - Auditorium', 75, 2),
('Children\'s Story Time', 'Weekly story time for children ages 3-6.', '2023-06-22', '10:00:00', '2023-06-22', '11:00:00', 'Main Library - Children\'s Section', 20, 3),
('Book Club Meeting', 'Monthly book club discussing "The Great Gatsby".', '2023-06-25', '19:00:00', '2023-06-25', '20:30:00', 'Main Library - Conference Room', 15, 4),
('Technology Workshop', 'Learn how to use e-readers and the library\'s e-book system.', '2023-06-28', '15:00:00', '2023-06-28', '16:30:00', 'Main Library - Computer Lab', 12, 5);

-- Insert Event Attendees
INSERT INTO event_attendees (event_id, member_id, attended) VALUES 
(1, 1, TRUE),
(1, 2, TRUE),
(1, 3, TRUE),
(1, 4, FALSE),
(2, 5, TRUE),
(2, 6, TRUE),
(2, 7, FALSE),
(3, 8, TRUE),
(3, 9, TRUE),
(4, 10, TRUE),
(4, 1, TRUE),
(5, 2, FALSE);

-- End of data insertion