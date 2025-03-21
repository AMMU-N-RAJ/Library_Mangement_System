import React, { useState } from 'react';

const LibraryDatabaseVisualizer = () => {
  const [activeTab, setActiveTab] = useState('schema');
  const [activeTable, setActiveTable] = useState('books');
  const [activeProcedure, setActiveProcedure] = useState(null);
  const [showRelationships, setShowRelationships] = useState(true);

  // Define database tables with their columns and relationships
  const tables = {
    books: {
      name: 'Books',
      primaryKey: 'book_id',
      columns: [
        { name: 'book_id', type: 'INT', description: 'Primary key - unique identifier for each book' },
        { name: 'isbn', type: 'VARCHAR(20)', description: 'International Standard Book Number - unique identifier in publishing' },
        { name: 'title', type: 'VARCHAR(255)', description: 'Book title' },
        { name: 'publisher_id', type: 'INT', description: 'Foreign key to publishers table' },
        { name: 'publication_date', type: 'DATE', description: 'Date when the book was published' },
        { name: 'total_copies', type: 'INT', description: 'Total number of copies owned by the library' },
        { name: 'available_copies', type: 'INT', description: 'Number of copies currently available for checkout' },
      ],
      relationships: [
        { to: 'publishers', type: 'many-to-one', via: 'publisher_id' },
        { to: 'book_authors', type: 'one-to-many', via: 'book_id' },
        { to: 'book_categories', type: 'one-to-many', via: 'book_id' },
        { to: 'loans', type: 'one-to-many', via: 'book_id' },
        { to: 'reservations', type: 'one-to-many', via: 'book_id' },
      ]
    },
    authors: {
      name: 'Authors',
      primaryKey: 'author_id',
      columns: [
        { name: 'author_id', type: 'INT', description: 'Primary key - unique identifier for each author' },
        { name: 'first_name', type: 'VARCHAR(50)', description: 'Author\'s first name' },
        { name: 'last_name', type: 'VARCHAR(50)', description: 'Author\'s last name' },
        { name: 'birth_date', type: 'DATE', description: 'Author\'s date of birth' },
        { name: 'nationality', type: 'VARCHAR(50)', description: 'Author\'s nationality' },
      ],
      relationships: [
        { to: 'book_authors', type: 'one-to-many', via: 'author_id' },
      ]
    },
    book_authors: {
      name: 'Book_Authors',
      primaryKey: 'book_id, author_id',
      columns: [
        { name: 'book_id', type: 'INT', description: 'Part of composite primary key and foreign key to books table' },
        { name: 'author_id', type: 'INT', description: 'Part of composite primary key and foreign key to authors table' },
      ],
      relationships: [
        { to: 'books', type: 'many-to-one', via: 'book_id' },
        { to: 'authors', type: 'many-to-one', via: 'author_id' },
      ]
    },
    publishers: {
      name: 'Publishers',
      primaryKey: 'publisher_id',
      columns: [
        { name: 'publisher_id', type: 'INT', description: 'Primary key - unique identifier for each publisher' },
        { name: 'name', type: 'VARCHAR(100)', description: 'Publisher name' },
        { name: 'address', type: 'TEXT', description: 'Publisher address' },
        { name: 'phone', type: 'VARCHAR(20)', description: 'Publisher phone number' },
        { name: 'email', type: 'VARCHAR(100)', description: 'Publisher email' },
      ],
      relationships: [
        { to: 'books', type: 'one-to-many', via: 'publisher_id' },
      ]
    },
    categories: {
      name: 'Categories',
      primaryKey: 'category_id',
      columns: [
        { name: 'category_id', type: 'INT', description: 'Primary key - unique identifier for each category' },
        { name: 'name', type: 'VARCHAR(50)', description: 'Category name (e.g. Fiction, Science, History)' },
        { name: 'description', type: 'TEXT', description: 'Category description' },
      ],
      relationships: [
        { to: 'book_categories', type: 'one-to-many', via: 'category_id' },
      ]
    },
    book_categories: {
      name: 'Book_Categories',
      primaryKey: 'book_id, category_id',
      columns: [
        { name: 'book_id', type: 'INT', description: 'Part of composite primary key and foreign key to books table' },
        { name: 'category_id', type: 'INT', description: 'Part of composite primary key and foreign key to categories table' },
      ],
      relationships: [
        { to: 'books', type: 'many-to-one', via: 'book_id' },
        { to: 'categories', type: 'many-to-one', via: 'category_id' },
      ]
    },
    members: {
      name: 'Members',
      primaryKey: 'member_id',
      columns: [
        { name: 'member_id', type: 'INT', description: 'Primary key - unique identifier for each member' },
        { name: 'first_name', type: 'VARCHAR(50)', description: 'Member\'s first name' },
        { name: 'last_name', type: 'VARCHAR(50)', description: 'Member\'s last name' },
        { name: 'email', type: 'VARCHAR(100)', description: 'Member\'s email address' },
        { name: 'membership_date', type: 'DATE', description: 'Date when membership started' },
        { name: 'membership_expiry', type: 'DATE', description: 'Date when membership expires' },
        { name: 'membership_status', type: 'ENUM', description: 'Status: Active, Expired, or Suspended' },
      ],
      relationships: [
        { to: 'loans', type: 'one-to-many', via: 'member_id' },
        { to: 'reservations', type: 'one-to-many', via: 'member_id' },
        { to: 'event_attendees', type: 'one-to-many', via: 'member_id' },
        { to: 'fines', type: 'one-to-many', via: 'member_id' },
      ]
    },
    staff: {
      name: 'Staff',
      primaryKey: 'staff_id',
      columns: [
        { name: 'staff_id', type: 'INT', description: 'Primary key - unique identifier for each staff member' },
        { name: 'first_name', type: 'VARCHAR(50)', description: 'Staff member\'s first name' },
        { name: 'last_name', type: 'VARCHAR(50)', description: 'Staff member\'s last name' },
        { name: 'position', type: 'VARCHAR(50)', description: 'Job title or position' },
        { name: 'is_admin', type: 'BOOLEAN', description: 'Whether the staff member has administrative privileges' },
      ],
      relationships: [
        { to: 'loans', type: 'one-to-many', via: 'issued_by_staff_id' },
        { to: 'loans', type: 'one-to-many', via: 'received_by_staff_id' },
        { to: 'fines', type: 'one-to-many', via: 'collected_by_staff_id' },
        { to: 'events', type: 'one-to-many', via: 'organized_by_staff_id' },
      ]
    },
    loans: {
      name: 'Loans',
      primaryKey: 'loan_id',
      columns: [
        { name: 'loan_id', type: 'INT', description: 'Primary key - unique identifier for each loan' },
        { name: 'book_id', type: 'INT', description: 'Foreign key to books table' },
        { name: 'member_id', type: 'INT', description: 'Foreign key to members table' },
        { name: 'loan_date', type: 'DATE', description: 'Date when the book was borrowed' },
        { name: 'due_date', type: 'DATE', description: 'Date when the book is due to be returned' },
        { name: 'return_date', type: 'DATE', description: 'Date when the book was actually returned (NULL if not returned)' },
        { name: 'returned', type: 'BOOLEAN', description: 'Whether the book has been returned' },
        { name: 'loan_status', type: 'ENUM', description: 'Status: Active, Returned, Overdue, or Lost' },
        { name: 'issued_by_staff_id', type: 'INT', description: 'Foreign key to staff table - who issued the book' },
        { name: 'received_by_staff_id', type: 'INT', description: 'Foreign key to staff table - who received the return' },
        { name: 'fine_amount', type: 'DECIMAL', description: 'Amount of fine for late return (if any)' },
      ],
      relationships: [
        { to: 'books', type: 'many-to-one', via: 'book_id' },
        { to: 'members', type: 'many-to-one', via: 'member_id' },
        { to: 'staff', type: 'many-to-one', via: 'issued_by_staff_id' },
        { to: 'staff', type: 'many-to-one', via: 'received_by_staff_id' },
        { to: 'fines', type: 'one-to-many', via: 'loan_id' },
      ]
    },
    reservations: {
      name: 'Reservations',
      primaryKey: 'reservation_id',
      columns: [
        { name: 'reservation_id', type: 'INT', description: 'Primary key - unique identifier for each reservation' },
        { name: 'book_id', type: 'INT', description: 'Foreign key to books table' },
        { name: 'member_id', type: 'INT', description: 'Foreign key to members table' },
        { name: 'reservation_date', type: 'TIMESTAMP', description: 'Date and time when the reservation was made' },
        { name: 'expiry_date', type: 'DATE', description: 'Date when the reservation expires' },
        { name: 'status', type: 'ENUM', description: 'Status: Pending, Fulfilled, Cancelled, or Expired' },
      ],
      relationships: [
        { to: 'books', type: 'many-to-one', via: 'book_id' },
        { to: 'members', type: 'many-to-one', via: 'member_id' },
      ]
    },
    fines: {
      name: 'Fines',
      primaryKey: 'fine_id',
      columns: [
        { name: 'fine_id', type: 'INT', description: 'Primary key - unique identifier for each fine' },
        { name: 'loan_id', type: 'INT', description: 'Foreign key to loans table' },
        { name: 'member_id', type: 'INT', description: 'Foreign key to members table' },
        { name: 'fine_amount', type: 'DECIMAL', description: 'Amount of the fine' },
        { name: 'reason', type: 'TEXT', description: 'Reason for the fine' },
        { name: 'issue_date', type: 'DATE', description: 'Date when the fine was issued' },
        { name: 'payment_date', type: 'DATE', description: 'Date when the fine was paid (NULL if not paid)' },
        { name: 'paid', type: 'BOOLEAN', description: 'Whether the fine has been paid' },
        { name: 'collected_by_staff_id', type: 'INT', description: 'Foreign key to staff table - who collected the payment' },
      ],
      relationships: [
        { to: 'loans', type: 'many-to-one', via: 'loan_id' },
        { to: 'members', type: 'many-to-one', via: 'member_id' },
        { to: 'staff', type: 'many-to-one', via: 'collected_by_staff_id' },
      ]
    },
    events: {
      name: 'Events',
      primaryKey: 'event_id',
      columns: [
        { name: 'event_id', type: 'INT', description: 'Primary key - unique identifier for each event' },
        { name: 'title', type: 'VARCHAR(255)', description: 'Event title' },
        { name: 'description', type: 'TEXT', description: 'Event description' },
        { name: 'start_date', type: 'DATE', description: 'Date when the event starts' },
        { name: 'start_time', type: 'TIME', description: 'Time when the event starts' },
        { name: 'end_date', type: 'DATE', description: 'Date when the event ends' },
        { name: 'end_time', type: 'TIME', description: 'Time when the event ends' },
        { name: 'location', type: 'VARCHAR(100)', description: 'Event location' },
        { name: 'max_attendees', type: 'INT', description: 'Maximum number of attendees allowed' },
        { name: 'organized_by_staff_id', type: 'INT', description: 'Foreign key to staff table - who organized the event' },
      ],
      relationships: [
        { to: 'staff', type: 'many-to-one', via: 'organized_by_staff_id' },
        { to: 'event_attendees', type: 'one-to-many', via: 'event_id' },
      ]
    },
    event_attendees: {
      name: 'Event_Attendees',
      primaryKey: 'event_id, member_id',
      columns: [
        { name: 'event_id', type: 'INT', description: 'Part of composite primary key and foreign key to events table' },
        { name: 'member_id', type: 'INT', description: 'Part of composite primary key and foreign key to members table' },
        { name: 'registration_date', type: 'TIMESTAMP', description: 'Date and time when the member registered for the event' },
        { name: 'attended', type: 'BOOLEAN', description: 'Whether the member actually attended the event' },
      ],
      relationships: [
        { to: 'events', type: 'many-to-one', via: 'event_id' },
        { to: 'members', type: 'many-to-one', via: 'member_id' },
      ]
    }
  };

  // Define stored procedures with details
  const procedures = [
    {
      name: 'issue_book',
      parameters: ['book_id', 'member_id', 'staff_id', 'loan_days'],
      description: 'Issues a book to a member',
      steps: [
        'Check if book is available',
        'Check if member is active',
        'Calculate due date',
        'Create loan record',
        'Trigger updates available_copies in books table'
      ]
    },
    {
      name: 'return_book',
      parameters: ['loan_id', 'staff_id'],
      description: 'Processes a book return',
      steps: [
        'Get loan details',
        'Calculate any fines for late return',
        'Update loan record to returned status',
        'Create fine record if needed',
        'Trigger updates available_copies in books table'
      ]
    },
    {
      name: 'search_books',
      parameters: ['title', 'author_name', 'category_name', 'publisher_name', 'available_only'],
      description: 'Searches for books based on various criteria',
      steps: [
        'Join multiple tables (books, authors, categories, publishers)',
        'Filter by any provided criteria',
        'Return matching books with related information'
      ]
    },
    {
      name: 'renew_loan',
      parameters: ['loan_id', 'renewal_days'],
      description: 'Extends the due date for an active loan',
      steps: [
        'Check if loan is active',
        'Calculate new due date',
        'Update loan record with new due date',
        'Add note about renewal'
      ]
    },
    {
      name: 'add_book',
      parameters: ['isbn', 'title', 'publisher_id', 'publication_date', 'edition', 'pages', 'language', 'description', 'shelf_location', 'total_copies', 'author_ids', 'category_ids'],
      description: 'Adds a new book to the library',
      steps: [
        'Insert book record',
        'Parse author_ids string into individual IDs',
        'Create book-author associations',
        'Parse category_ids string into individual IDs',
        'Create book-category associations'
      ]
    }
  ];

  // Define triggers with details
  const triggers = [
    {
      name: 'after_loan_insert',
      table: 'loans',
      timing: 'AFTER INSERT',
      description: 'Decrements the available_copies count when a book is borrowed',
      code: `UPDATE books SET available_copies = available_copies - 1 WHERE book_id = NEW.book_id;`
    },
    {
      name: 'after_loan_update',
      table: 'loans',
      timing: 'AFTER UPDATE',
      description: 'Increments the available_copies count when a book is returned',
      code: `IF NEW.returned = TRUE AND OLD.returned = FALSE THEN
  UPDATE books SET available_copies = available_copies + 1 WHERE book_id = NEW.book_id;
END IF;`
    }
  ];

  // Define views with details
  const views = [
    {
      name: 'vw_available_books',
      description: 'Shows all books that are currently available for checkout',
      tables: ['books', 'book_authors', 'authors', 'publishers', 'book_categories', 'categories'],
      filters: ['books.available_copies > 0']
    },
    {
      name: 'vw_overdue_loans',
      description: 'Shows all loans that are past their due date and not returned',
      tables: ['loans', 'books', 'members'],
      filters: ['loans.returned = FALSE', 'loans.due_date < CURRENT_DATE'],
      calculations: ['DATEDIFF(CURRENT_DATE, loans.due_date) AS days_overdue', 'DATEDIFF(CURRENT_DATE, loans.due_date) * 0.50 AS estimated_fine']
    },
    {
      name: 'vw_book_inventory',
      description: 'Shows complete inventory information for all books',
      tables: ['books', 'book_authors', 'authors', 'publishers', 'book_categories', 'categories'],
      calculations: ['(books.total_copies - books.available_copies) AS checked_out_copies']
    }
  ];

  // Colors for entities in the diagram
  const colors = {
    core: 'bg-blue-600', // Core tables
    junction: 'bg-purple-600', // Junction tables
    transaction: 'bg-green-600', // Transaction tables
    reference: 'bg-yellow-600', // Reference tables
    event: 'bg-red-600' // Event-related tables
  };

  // Categorize tables by type
  const tableTypes = {
    books: colors.core,
    authors: colors.core,
    publishers: colors.reference,
    categories: colors.reference,
    book_authors: colors.junction,
    book_categories: colors.junction,
    members: colors.core,
    staff: colors.core,
    loans: colors.transaction,
    reservations: colors.transaction,
    fines: colors.transaction,
    events: colors.event,
    event_attendees: colors.junction
  };

  // Function to get position for a table in diagram
  const getPosition = (tableName: string, index?: number) => {
    const positions = {
      books: { x: 400, y: 250 },
      authors: { x: 150, y: 150 },
      publishers: { x: 650, y: 150 },
      categories: { x: 650, y: 350 },
      book_authors: { x: 250, y: 250 },
      book_categories: { x: 550, y: 300 },
      members: { x: 250, y: 450 },
      staff: { x: 550, y: 450 },
      loans: { x: 400, y: 350 },
      reservations: { x: 150, y: 350 },
      fines: { x: 400, y: 450 },
      events: { x: 650, y: 550 },
      event_attendees: { x: 400, y: 550 }
    };
    return positions[tableName as keyof typeof positions] || { x: 100 + (index % 5) * 150, y: 100 + Math.floor(index / 5) * 100 };

  };

  // Path calculation for relationships
  const getPath = (source, target) => {
    const sourcePos = getPosition(source);
    const targetPos = getPosition(target);
    
    return `M${sourcePos.x},${sourcePos.y} C${(sourcePos.x + targetPos.x)/2},${sourcePos.y} ${(sourcePos.x + targetPos.x)/2},${targetPos.y} ${targetPos.x},${targetPos.y}`;
  };

  const handleTableClick = (tableName) => {
    setActiveTable(tableName);
    setActiveProcedure(null);
  };

  const handleProcedureClick = (procedureName) => {
    setActiveProcedure(procedureName);
    setActiveTable(null);
  };

  const getTableDetails = () => {
    if (!activeTable) return null;
    const table = tables[activeTable];
    
    return (
      <div className="mt-4">
        <h3 className="text-lg font-bold mb-2">{table.name} Table</h3>
        <p className="mb-2"><span className="font-semibold">Primary Key:</span> {table.primaryKey}</p>
        
        <h4 className="font-semibold mt-3 mb-1">Columns:</h4>
        <table className="w-full border-collapse">
          <thead>
            <tr className="bg-gray-100">
              <th className="border p-2 text-left">Name</th>
              <th className="border p-2 text-left">Type</th>
              <th className="border p-2 text-left">Description</th>
            </tr>
          </thead>
          <tbody>
            {table.columns.map((column) => (
              <tr key={column.name} className="border-b">
                <td className="border p-2">{column.name}</td>
                <td className="border p-2">{column.type}</td>
                <td className="border p-2">{column.description}</td>
              </tr>
            ))}
          </tbody>
        </table>
        
        <h4 className="font-semibold mt-4 mb-1">Relationships:</h4>
        <ul className="list-disc pl-5">
          {table.relationships.map((rel, idx) => (
            <li key={idx}>
              <span className="font-medium">{rel.type}</span> relationship with{' '}
              <button 
                onClick={() => handleTableClick(rel.to)}
                className="text-blue-600 hover:underline"
              >
                {tables[rel.to]?.name || rel.to}
              </button>
              {rel.via ? ` via ${rel.via}` : ''}
            </li>
          ))}
        </ul>
      </div>
    );
  };

  const getProcedureDetails = () => {
    if (!activeProcedure) return null;
    const procedure = procedures.find(p => p.name === activeProcedure);
    if (!procedure) return null;
    
    return (
      <div className="mt-4">
        <h3 className="text-lg font-bold mb-2">Stored Procedure: {procedure.name}</h3>
        <p className="mb-2">{procedure.description}</p>
        
        <h4 className="font-semibold mt-3 mb-1">Parameters:</h4>
        <ul className="list-disc pl-5 mb-4">
          {procedure.parameters.map((param, idx) => (
            <li key={idx}>{param}</li>
          ))}
        </ul>
        
        <h4 className="font-semibold mb-1">Implementation Steps:</h4>
        <ol className="list-decimal pl-5">
          {procedure.steps.map((step, idx) => (
            <li key={idx}>{step}</li>
          ))}
        </ol>
      </div>
    );
  };

  const renderSchemaTab = () => {
    return (
      <div className="p-4">
        <div className="flex mb-4 space-x-2">
          <button 
            className={`px-3 py-1 rounded ${showRelationships ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
            onClick={() => setShowRelationships(!showRelationships)}
          >
            {showRelationships ? 'Hide Relationships' : 'Show Relationships'}
          </button>
          <select 
            className="px-3 py-1 rounded border"
            value={activeTable || ""}
            onChange={(e) => {
              handleTableClick(e.target.value);
            }}
          >
            <option value="">Select a table...</option>
            {Object.keys(tables).map(tableName => (
              <option key={tableName} value={tableName}>
                {tables[tableName].name}
              </option>
            ))}
          </select>
        </div>

        <div className="bg-gray-100 p-2 mb-4 rounded">
          <div className="flex items-center space-x-4 mb-2">
            <span className="font-semibold">Table Types:</span>
            <span className="flex items-center"><div className="w-4 h-4 bg-blue-600 rounded-full mr-1"></div> Core</span>
            <span className="flex items-center"><div className="w-4 h-4 bg-purple-600 rounded-full mr-1"></div> Junction</span>
            <span className="flex items-center"><div className="w-4 h-4 bg-green-600 rounded-full mr-1"></div> Transaction</span>
            <span className="flex items-center"><div className="w-4 h-4 bg-yellow-600 rounded-full mr-1"></div> Reference</span>
            <span className="flex items-center"><div className="w-4 h-4 bg-red-600 rounded-full mr-1"></div> Event</span>
          </div>
        </div>

        <div className="relative h-96 border rounded-lg overflow-auto">
          <svg width="800" height="700" className="bg-white">
            {/* Draw relationships */}
            {showRelationships && Object.entries(tables).map(([tableName, table]) => {
              return table.relationships.map((rel, idx) => (
                <path
                  key={`${tableName}-${rel.to}-${idx}`}
                  d={getPath(tableName, rel.to)}
                  stroke="#aaa"
                  strokeWidth="1.5"
                  fill="none"
                  markerEnd="url(#arrowhead)"
                  strokeDasharray={rel.type.includes('many') ? "5,5" : ""}
                />
              ));
            })}
            
            {/* Draw table nodes */}
            {Object.entries(tables).map(([tableName, table], index) => {
              const position = getPosition(tableName, index);
              return (
                <g 
                  key={tableName} 
                  transform={`translate(${position.x - 60}, ${position.y - 20})`}
                  onClick={() => handleTableClick(tableName)}
                  style={{ cursor: 'pointer' }}
                >
                  <rect
                    width="120"
                    height="40"
                    rx="5"
                    ry="5"
                    fill={tableTypes[tableName]}
                    stroke={activeTable === tableName ? '#000' : 'none'}
                    strokeWidth={activeTable === tableName ? '2' : '0'}
                  />
                  <text
                    x="60"
                    y="25"
                    textAnchor="middle"
                    fill="white"
                    fontWeight={activeTable === tableName ? 'bold' : 'normal'}
                  >
                    {table.name}
                  </text>
                </g>
              );
            })}
            
            {/* SVG definitions */}
            <defs>
              <marker
                id="arrowhead"
                viewBox="0 0 10 10"
                refX="5"
                refY="5"
                markerWidth="6"
                markerHeight="6"
                orient="auto-start-reverse"
              >
                <path d="M 0 0 L 10 5 L 0 10 z" fill="#aaa" />
              </marker>
            </defs>
          </svg>
        </div>
        
        {getTableDetails()}
      </div>
    );
  };

  const renderOperationsTab = () => {
    return (
      <div className="p-4">
        <div className="mb-4">
          <h3 className="text-lg font-bold mb-2">Stored Procedures</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {procedures.map(proc => (
              <div 
                key={proc.name}
                className={`p-3 border rounded cursor-pointer hover:bg-blue-50 ${activeProcedure === proc.name ? 'bg-blue-100 border-blue-500' : ''}`}
                onClick={() => handleProcedureClick(proc.name)}
              >
                <h4 className="font-semibold">{proc.name}</h4>
                <p className="text-sm text-gray-600">{proc.description}</p>
              </div>
            ))}
          </div>
        </div>
        
        <div className="mb-4">
          <h3 className="text-lg font-bold mb-2">Triggers</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {triggers.map(trigger => (
              <div 
                key={trigger.name}
                className="p-3 border rounded"
              >
                <h4 className="font-semibold">{trigger.name}</h4>
                <p className="text-sm text-gray-600 mb-1">{trigger.timing} on {trigger.table}</p>
                <p className="text-sm">{trigger.description}</p>
                <pre className="mt-2 bg-gray-100 p-2 rounded text-xs overflow-x-auto">
                  {trigger.code}
                </pre>
              </div>
            ))}
          </div>
        </div>
        
        <div className="mb-4">
          <h3 className="text-lg font-bold mb-2">Views</h3>
          <div className="grid grid-cols-1 gap-4">
            {views.map(view => (
              <div 
                key={view.name}
                className="p-3 border rounded"
              >
                <h4 className="font-semibold">{view.name}</h4>
                <p className="text-sm">{view.description}</p>
                <div className="mt-2 text-sm">
                  <p><span className="font-medium">Tables:</span> {view.tables.join(', ')}</p>
                  {view.filters && (
                    <p><span className="font-medium">Filters:</span> {view.filters.join(', ')}</p>
                  )}
                  {view.calculations && (
                    <p><span className="font-medium">Calculations:</span> {view.calculations.join(', ')}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
        
        {getProcedureDetails()}
      </div>
    );
  };

  const renderWorkflowTab = () => {
    return (
      <div className="p-4">
        <h3 className="text-lg font-bold mb-4">Common Library Workflows</h3>
        
        <div className="mb-6 border rounded-lg p-4 bg-blue-50">
          <h4 className="font-bold text-lg mb-2">Book Checkout Process</h4>
          <div className="relative">
            {/* Workflow diagram */}
            <div className="flex flex-col items-center">
              {/* Step 1 */}
              <div className="mb-8 text-center">
                <div className="w-32 p-2 bg-blue-600 text-white rounded mx-auto">
                  Member Request
                </div>
                <div className="text-sm mt-1">Member requests to borrow a book</div>
              </div>
              
              {/* Arrow */}
              <div className="h-8 w-0.5 bg-gray-400 -mt-6 mb-2"></div>
              
              {/* Step 2 */}
              <div className="mb-8 text-center">
                <div className="w-32 p-2 bg-blue-600 text-white rounded mx-auto">
                  Check Availability
                </div>
                <div className="text-sm mt-1">
                  <code>issue_book</code> procedure checks if book is available
                </div>
              </div>
              
              {/* Arrow */}
              <div className="h-8 w-0.5 bg-gray-400 -mt-6 mb-2"></div>
              
              {/* Step 3 */}
              <div className="mb-8 text-center">
                <div className="w-40 p-2 bg-blue-600 text-white rounded mx-auto">
                  Book Issued
                </div>
                <div className="text-sm mt-1">
                  Creates loan record and calls <code>after_loan_insert</code> trigger
                </div>
              </div>
              
              {/* Arrow */}
              <div className="h-8 w-0.5 bg-gray-400 -mt-6 mb-2"></div>
              
              {/* Step 4 */}
              <div className="text-center">
                <div className="w-40 p-2 bg-blue-600 text-white rounded mx-auto">
                  Available Copies Updated
                </div>
                <div className="text-sm mt-1">
                  Trigger decrements available_copies in books table
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div className="mb-6 border rounded-lg p-4 bg-green-50">
          <h4 className="font-bold text-lg mb-2">Book Return Process</h4>
          <div className="relative">
            <div className="flex flex-col items-center">
              {/* Step 1 */}
              <div className="mb-8 text-center">
                <div className="w-32 p-2 bg-green-600 text-white rounded mx-auto">
                  Book Return
                </div>
                <div className="text-sm mt-1">Member returns a book</div>
              </div>
              
              {/* Arrow */}
              <div className="h-8 w-0.5 bg-gray-400 -mt-6 mb-2"></div>
              
              {/* Step 2 */}
              <div className="mb-8 text-center">
                <div className="w-32 p-2 bg-green-600 text-white rounded mx-auto">
                  Check Due Date
                </div>
                <div className="text-sm mt-1">
                  <code>return_book</code> procedure checks if return is late
                </div>
              </div>
              
              {/* Arrow */}
              <div className="h-8 w-0.5 bg-gray-400 -mt-6 mb-2"></div>
              
              {/* Step 3 with branching */}
              <div className="mb-12 text-center">
                <div className="w-40 p-2 bg-green-600 text-white rounded mx-auto">
                  Late Return?
                </div>
                <div className="flex justify-center mt-8">
                  <div className="text-center mx-8">
                    <div className="w-24 p-2 bg-red-500 text-white rounded mx-auto">
                      Yes
                    </div>
                    <div className="h-8 w-0.5 bg-gray-400 mx-auto mt-2 mb-2"></div>
                    <div className="w-28 p-2 bg-red-500 text-white rounded mx-auto">
                      Create Fine
                    </div>
                  </div>
                  <div className="text-center mx-8">
                    <div className="w-24 p-2 bg-green-500 text-white rounded mx-auto">
                      No
                    </div>
                    <div className="h-8 w-0.5 bg-gray-400 mx-auto mt-2 mb-2"></div>
                    <div className="w-28 p-2 bg-green-500 text-white rounded mx-auto">
                      No Fine
                    </div>
                  </div>
                </div>
              </div>
              
              {/* Arrow */}
              <div className="h-8 w-0.5 bg-gray-400 -mt-8 mb-2"></div>
              
              {/* Step 4 */}
              <div className="mb-8 text-center">
                <div className="w-40 p-2 bg-green-600 text-white rounded mx-auto">
                  Update Loan Status
                </div>
                <div className="text-sm mt-1">
                  Mark loan as returned, update return_date
                </div>
              </div>
              
              {/* Arrow */}
              <div className="h-8 w-0.5 bg-gray-400 -mt-6 mb-2"></div>
              
              {/* Step 5 */}
              <div className="text-center">
                <div className="w-40 p-2 bg-green-600 text-white rounded mx-auto">
                  Update Book Availability
                </div>
                <div className="text-sm mt-1">
                  <code>after_loan_update</code> trigger increments available_copies
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="max-w-6xl mx-auto bg-white rounded-lg shadow-lg overflow-hidden">
      <div className="bg-gradient-to-r from-blue-700 to-purple-700 text-white p-4">
        <h2 className="text-xl font-bold">Library Management System Database Visualization</h2>
        <p className="text-sm opacity-90">Interactive exploration of database structure and functionality</p>
        <p className="text-sm mt-1 font-medium">Author: ammunraj</p>
      </div>
      
      <div className="border-b">
        <nav className="flex">
          <button
            className={`px-4 py-2 font-medium ${activeTab === 'schema' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-500'}`}
            onClick={() => setActiveTab('schema')}
          >
            Database Schema
          </button>
          <button
            className={`px-4 py-2 font-medium ${activeTab === 'operations' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-500'}`}
            onClick={() => setActiveTab('operations')}
          >
            Procedures & Triggers
          </button>
          <button
            className={`px-4 py-2 font-medium ${activeTab === 'workflow' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-500'}`}
            onClick={() => setActiveTab('workflow')}
          >
            Library Workflows
          </button>
        </nav>
      </div>
      
      <div className="bg-white">
        {activeTab === 'schema' && renderSchemaTab()}
        {activeTab === 'operations' && renderOperationsTab()}
        {activeTab === 'workflow' && renderWorkflowTab()}
      </div>
    </div>
  );
};

export default LibraryDatabaseVisualizer;
